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
git --git-dir=.git/modules/3rdparty/OpenAL/openal-soft --work-tree=3rdparty/OpenAL/openal-soft checkout 50a777be67adb66a453aa26a92cb9c7edb8a5cec
git submodule status 3rdparty/OpenAL/openal-soft

# 1. Revert the "Strong Casts" back to standard functional casts
sed -i 's/gsl::narrow_cast/static_cast/g' 3rdparty/OpenAL/openal-soft/alc/backends/pipewire.cpp

# 2. Convert OpenAL aliases to standard single-word types (compatible with {} init)
sed -i 's/\bu64\b/uint64_t/g' 3rdparty/OpenAL/openal-soft/alc/backends/pipewire.cpp
sed -i 's/\buint32_t\b/uint32_t/g' 3rdparty/OpenAL/openal-soft/alc/backends/pipewire.cpp

# 3. Remove the internal '.c_val' accessors (only used by the Strong Types)
sed -i 's/\.c_val//g' 3rdparty/OpenAL/openal-soft/alc/backends/pipewire.cpp

# 4. Fix specific multi-word type errors in initialization lists
sed -i 's/unsigned int{/uint32_t{/g' 3rdparty/OpenAL/openal-soft/alc/backends/pipewire.cpp
sed -i 's/unsigned long long{/uint64_t{/g' 3rdparty/OpenAL/openal-soft/alc/backends/pipewire.cpp

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
    -G Ninja

ninja; build_status=$?;

cd ..

# If it compiled succesfully let's deploy.
if [ "$build_status" -eq 0 ]; then
    .ci/deploy-linux.sh "aarch64"
fi
