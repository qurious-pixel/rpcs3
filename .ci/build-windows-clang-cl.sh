#!/bin/sh -e

echo "Starting RPCS3 build (Bash script)"

# Automatically find clang_rt.builtins-x86_64.lib
echo "Searching for clang_rt.builtins-x86_64.lib ..."
clangBuiltinsLibPath=$(find "C:\\Program Files\\LLVM\\lib\\clang" -name "clang_rt.builtins-x86_64.lib" 2>/dev/null | grep "windows/clang_rt.builtins-x86_64.lib" | head -n 1)

if [[ -z "$clangBuiltinsLibPath" ]]; then
    echo "ERROR: Could not find clang_rt.builtins-x86_64.lib in LLVM installation."
    exit 1
fi

clangBuiltinsDir=$(dirname "$clangBuiltinsLibPath")
clangBuiltinsLib=$(basename "$clangBuiltinsLibPath")
clangPath="C:\\PROGRA~1\\LLVM\\bin\\"

echo "Found Clang builtins library: $clangBuiltinsLib in $clangBuiltinsDir"
echo "Found Clang Path: $clangPath"

# Search for mt.exe in SDK bin directories
echo "Searching for llvm-mt.exe ..."
mtPath=$(find "$clangPath" -name "llvm-mt.exe" 2>/dev/null | grep "llvm-mt.exe" | sort -r | head -n 1)

if [[ -z "$mtPath" ]]; then
    echo "ERROR: Could not find llvm-mt.exe in SDK directories."
    exit 1
fi

echo "Found llvm-mt.exe at: $mtPath"

VcpkgRoot="$(pwd)/vcpkg"
VcpkgTriplet="$VCPKG_TRIPLET"
VcpkgInstall="$VcpkgRoot/installed/$VcpkgTriplet"
VcpkgInclude="$VcpkgInstall/include"
VcpkgLib="$VcpkgInstall/lib"
VcpkgBin="$VcpkgInstall/bin"

# Configure git safe directory
echo "Configuring git safe directory"
git config --global --add safe.directory '*'

# Initialize submodules except certain ones
echo "Initializing submodules"
excludedSubs=("llvm" "opencv" "ffmpeg" "FAudio" "zlib" "libpng" "feralinteractive")

# Get submodule paths excluding those in excludedSubs
readarray -t submodules < <(grep 'path = ' .gitmodules | sed 's/path = //' | grep -v -E "$(IFS=\|; echo "${excludedSubs[*]}")")

echo "Updating submodules: ${submodules[*]}"
git submodule update --init --quiet ${submodules[@]}

# Create and enter build directory
echo "Creating build directory"
mkdir -p build
cd build || exit
echo "Changed directory to: $(pwd)"

# Run CMake with Ninja generator and required flags
echo "Running CMake configuration"
cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="$clangPath\\clang-cl.exe" \
    -DCMAKE_CXX_COMPILER="$clangPath\\clang-cl.exe" \
    -DCMAKE_LINKER="$clangPath\\lld-link.exe" \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_TOOLCHAIN_FILE="$VcpkgRoot/scripts/buildsystems/vcpkg.cmake" \
    -DCMAKE_EXE_LINKER_FLAGS="/LIBPATH:$clangBuiltinsDir /defaultlib:$clangBuiltinsLib" \
    -DCMAKE_MT="$mtPath" \
    -DUSE_NATIVE_INSTRUCTIONS=OFF \
    -DUSE_PRECOMPILED_HEADERS=OFF \
    -DVCPKG_TARGET_TRIPLET="$VcpkgTriplet" \
    -DFFMPEG_INCLUDE_DIR="$VcpkgInclude" \
    -DFFMPEG_LIBAVCODEC="$VcpkgLib/avcodec.lib" \
    -DFFMPEG_LIBAVFORMAT="$VcpkgLib/avformat.lib" \
    -DFFMPEG_LIBAVUTIL="$VcpkgLib/avutil.lib" \
    -DFFMPEG_LIBSWSCALE="$VcpkgLib/swscale.lib" \
    -DFFMPEG_LIBSWRESAMPLE="$VcpkgLib/swresample.lib" \
    -DUSE_SYSTEM_CURL=OFF \
    -DUSE_FAUDIO=OFF \
    -DUSE_SDL=ON \
    -DUSE_SYSTEM_SDL=OFF \
    -DUSE_SYSTEM_FFMPEG=ON \
    -DUSE_SYSTEM_OPENCV=ON \
    -DUSE_SYSTEM_OPENAL=OFF \
    -DUSE_SYSTEM_LIBPNG=ON \
    -DUSE_DISCORD_RPC=ON \
    -DUSE_SYSTEM_ZSTD=ON \
    -DWITH_LLVM=ON \
    -DSTATIC_LINK_LLVM=ON \
    -DBUILD_RPCS3_TESTS=OFF

echo "CMake configuration complete"

# Build with ninja
echo "Starting build with Ninja..."
ninja

if [[ $? -ne 0 ]]; then
    echo "Build failed with exit code $?"
    exit 1
fi

echo "Build succeeded"

# Go back to root directory
cd ..
echo "Returned to root directory: $(pwd)"
