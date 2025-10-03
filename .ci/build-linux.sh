#!/bin/sh -ex

cd rpcs3 || exit 1

shellcheck .ci/*.sh

git config --global --add safe.directory '*'

curl -LO https://ffmpeg.org/releases/ffmpeg-"$FFMPEG_VER".tar.gz
        tar -xzf ffmpeg-"$FFMPEG_VER".tar.gz
        cd ffmpeg-"$FFMPEG_VER"
        ./configure --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --incdir=/usr/include/x86_64-linux-gnu --enable-pic --disable-doc --enable-runtime-cpudetect --disable-autodetect --disable-everything --disable-x86asm \
--enable-decoder=aac --enable-decoder=aac_latm --enable-decoder=atrac3 --enable-decoder=atrac3p --enable-decoder=atrac9 --enable-decoder=mp3 --enable-decoder=pcm_s16le --enable-decoder=pcm_s8 \
--enable-decoder=mov --enable-decoder=h264 --enable-decoder=mpeg4 --enable-decoder=mpeg2video --enable-decoder=mjpeg --enable-decoder=mjpegb \
--enable-encoder=pcm_s16le --enable-encoder=mp3 --enable-encoder=ac3 --enable-encoder=aac \
--enable-encoder=ffv1 --enable-encoder=mpeg4 --enable-encoder=mjpeg --enable-encoder=h264 \
--enable-muxer=avi --enable-muxer=h264 --enable-muxer=mjpeg --enable-muxer=mp4 \
--enable-demuxer=h264 --enable-demuxer=m4v --enable-demuxer=mp3 --enable-demuxer=mpegvideo --enable-demuxer=mpegps --enable-demuxer=mjpeg --enable-demuxer=mov --enable-demuxer=avi --enable-demuxer=aac --enable-demuxer=pmp --enable-demuxer=oma --enable-demuxer=pcm_s16le --enable-demuxer=pcm_s8 --enable-demuxer=wav \
--enable-parser=h264 --enable-parser=mpeg4video --enable-parser=mpegaudio --enable-parser=mpegvideo --enable-parser=mjpeg --enable-parser=aac --enable-parser=aac_latm \
 --enable-protocol=file --enable-bsf=mjpeg2jpeg --enable-indev=dshow
        make
        make install
        ffmpeg -version
        cd -

# Pull all the submodules except some
# Note: Tried to use git submodule status, but it takes over 20 seconds
# shellcheck disable=SC2046
git submodule -q update --init $(awk '/path/ && !/llvm/ && !/opencv/ && !/libsdl-org/ && !/curl/ && !/zlib/ { print $3 }' .gitmodules)



mkdir build && cd build || exit 1

if [ "$COMPILER" = "gcc" ]; then
    # These are set in the dockerfile
    export CC="${GCC_BINARY}"
    export CXX="${GXX_BINARY}"
    export LINKER=gold
    # We need to set the following variables for LTO to link properly
    export AR=/usr/bin/gcc-ar-"$GCCVER"
    export RANLIB=/usr/bin/gcc-ranlib-"$GCCVER"
    export CFLAGS="-fuse-linker-plugin"
else
    export CC="${CLANG_BINARY}"
    export CXX="${CLANGXX_BINARY}"
    export LINKER=lld
    export AR=/usr/bin/llvm-ar-"$LLVMVER"
    export RANLIB=/usr/bin/llvm-ranlib-"$LLVMVER"
fi

export LINKER_FLAG="-fuse-ld=${LINKER}"

cmake ..                                               \
    -DCMAKE_INSTALL_PREFIX=/usr                        \
    -DUSE_NATIVE_INSTRUCTIONS=OFF                      \
    -DUSE_PRECOMPILED_HEADERS=OFF                      \
    -DCMAKE_C_FLAGS="$CFLAGS"                          \
    -DCMAKE_CXX_FLAGS="$CFLAGS"                        \
    -DCMAKE_EXE_LINKER_FLAGS="${LINKER_FLAG}"          \
    -DCMAKE_MODULE_LINKER_FLAGS="${LINKER_FLAG}"       \
    -DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAG}"       \
    -DCMAKE_AR="$AR"                                   \
    -DCMAKE_RANLIB="$RANLIB"                           \
    -DUSE_SYSTEM_CURL=ON                               \
    -DUSE_SDL=ON                                       \
    -DUSE_SYSTEM_SDL=ON                                \
    -DUSE_SYSTEM_FFMPEG=ON                             \
    -DUSE_SYSTEM_OPENCV=ON                             \
    -DUSE_DISCORD_RPC=ON                               \
    -DOpenGL_GL_PREFERENCE=LEGACY                      \
    -DLLVM_DIR=/opt/llvm/lib/cmake/llvm                \
    -DSTATIC_LINK_LLVM=ON                              \
    -G Ninja

ninja; build_status=$?;

cd ..

# If it compiled succesfully let's deploy.
if [ "$build_status" -eq 0 ]; then
    .ci/deploy-linux.sh "x86_64"
fi
