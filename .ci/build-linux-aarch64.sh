#!/bin/sh -ex

cd rpcs3 || exit 1

shellcheck .ci/*.sh

git config --global --add safe.directory '*'

# Pull all the submodules except some
# shellcheck disable=SC2046
git submodule -q update --init $(awk '/path/ && !/llvm/ && !/opencv/ && !/libsdl-org/ && !/curl/ && !/zlib/ { print $3 }' .gitmodules)
#OPENAL Fixes
#sed -i '1i #include <cstdint>' 3rdparty/OpenAL/openal-soft/common/altypes.hpp
git --git-dir=.git/modules/3rdparty/OpenAL/openal-soft fetch origin
git --git-dir=.git/modules/3rdparty/OpenAL/openal-soft --work-tree=3rdparty/OpenAL/openal-soft checkout c41d64c6a35f6174bf4a27010aeac52a8d3bb2c6
git submodule status 3rdparty/OpenAL/openal-soft

mkdir build && cd build || exit 1

if [ "$COMPILER" = "gcc" ]; then
    # These are set in the dockerfile
    export CC="${GCC_BINARY}"
    export CXX="${GXX_BINARY}"
    export LINKER=gold
else
    export CC="${CLANG_BINARY}"
    export CXX="${CLANGXX_BINARY}"
    export LINKER="${LLD_BINARY}"
fi

export LINKER_FLAG="-fuse-ld=${LINKER}"

cmake ..                                               \
    -DCMAKE_INSTALL_PREFIX=/usr                        \
    -DUSE_NATIVE_INSTRUCTIONS=OFF                      \
    -DUSE_PRECOMPILED_HEADERS=OFF                      \
    -DCMAKE_EXE_LINKER_FLAGS="${LINKER_FLAG}"          \
    -DCMAKE_MODULE_LINKER_FLAGS="${LINKER_FLAG}"       \
    -DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAG}"       \
    -DUSE_SYSTEM_CURL=ON                               \
    -DUSE_SDL=ON                                       \
    -DUSE_SYSTEM_SDL=ON                                \
    -DUSE_SYSTEM_FFMPEG=OFF                            \
    -DUSE_SYSTEM_OPENCV=ON                             \
    -DUSE_DISCORD_RPC=ON                               \
    -DOpenGL_GL_PREFERENCE=LEGACY                      \
    -DLLVM_DIR=/opt/llvm/lib/cmake/llvm                \
    -DSTATIC_LINK_LLVM=ON                              \
    -DBUILD_RPCS3_TESTS="${RUN_UNIT_TESTS}"            \
    -DRUN_RPCS3_TESTS="${RUN_UNIT_TESTS}"              \
    -DQT_QPA_PLATFORM="offscreen"                      \
    -G Ninja

ninja; build_status=$?;

cd ..

# If it compiled succesfully let's deploy.
if [ "$build_status" -eq 0 ]; then
    .ci/deploy-linux.sh "aarch64"
fi
