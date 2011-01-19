#!/bin/sh

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

LIBRARY_DIRECTORY_DEBUG=./stage/lib/debug
LIBRARY_DIRECTORY_RELEASE=./stage/lib/release
BINARY_DIRECTORY=./stage/bin
INCLUDE_DIRECTORY=./stage/include/google_breakpad
mkdir -p "$LIBRARY_DIRECTORY_DEBUG"
mkdir -p "$LIBRARY_DIRECTORY_RELEASE"
mkdir -p "$BINARY_DIRECTORY"
mkdir -p "$INCLUDE_DIRECTORY"

case "$AUTOBUILD_PLATFORM" in
    "windows")
        (
            cd src/client/windows
            ../../tools/gyp/gyp --msvs-version=2005
        )
        build_sln src/client/windows/breakpad_client.sln "release|win32" exception_handler
        build_sln src/client/windows/breakpad_client.sln "debug|win32" exception_handler
        build_sln src/client/windows/breakpad_client.sln "release|win32" crash_generation_client
        build_sln src/client/windows/breakpad_client.sln "debug|win32" crash_generation_client
        build_sln src/client/windows/breakpad_client.sln "release|win32" common
        build_sln src/client/windows/breakpad_client.sln "debug|win32" common
        build_vcproj src/tools/windows/dump_syms/dump_syms.vcproj "release|win32"
        mkdir -p "$INCLUDE_DIRECTORY/client/windows/"{common,crash_generation}
        mkdir -p "$INCLUDE_DIRECTORY/common/windows"
        mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
        mkdir -p "$INCLUDE_DIRECTORY/processor"
        cp ./src/client/windows/handler/exception_handler.h "$INCLUDE_DIRECTORY"
        cp src/client/windows/common/*.h "$INCLUDE_DIRECTORY/client/windows/common"
        cp src/common/windows/*.h "$INCLUDE_DIRECTORY/common/windows"
        cp src/client/windows/crash_generation/*.h "$INCLUDE_DIRECTORY/client/windows/crash_generation"
        cp src/google_breakpad/common/*.h "$INCLUDE_DIRECTORY/google_breakpad/common"
        cp src/processor/scoped_ptr.*h "$INCLUDE_DIRECTORY/processor"
        cp ./src/client/windows/Debug/lib/*.lib "$LIBRARY_DIRECTORY_DEBUG"
        cp ./src/client/windows/Release/lib/*.lib "$LIBRARY_DIRECTORY_RELEASE"
        cp ./src/tools/windows/dump_syms/Release/dump_syms.exe "$BINARY_DIRECTORY"
    ;;
    darwin)
        (
            cd src/
            cmake -G Xcode CMakeLists.txt
            xcodebuild -project google_breakpad.xcodeproj GCC_VERSION=4.0 MACOSX_DEPLOYMENT_TARGET=10.4 -sdk macosx10.4 -configuration Release
        )
		# *TODO - fix the release build of the dump_syms tool
        xcodebuild -project src/tools/mac/dump_syms/dump_syms.xcodeproj GCC_VERSION=4.0 MACOSX_DEPLOYMENT_TARGET=10.4 -sdk macosx10.4 -configuration Debug
        cp ./src/client/mac/handler/exception_handler.h "$INCLUDE_DIRECTORY"
        cp ./src/client/mac/handler/Release/libexception_handler.dylib "$LIBRARY_DIRECTORY_RELEASE"
        cp ./src/tools/mac/dump_syms/build/Debug/dump_syms "$BINARY_DIRECTORY"
    ;;
    linux)
        VIEWER_FLAGS="-m32 -fno-stack-protector"
        ./configure --prefix="$(pwd)/stage" CFLAGS="$VIEWER_FLAGS" CXXFLAGS="$VIEWER_FLAGS" LDFLAGS=-m32
        make
        make -C src/tools/linux/dump_syms/ dump_syms
        make install
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/"{handler,crash_generation}
        cp -P stage/lib/libbreakpad*.so* "$LIBRARY_DIRECTORY_RELEASE"
        cp src/client/linux/handler/*.h "$INCLUDE_DIRECTORY"
        cp src/client/linux/crash_generation/*.h "$INCLUDE_DIRECTORY/client/linux/crash_generation"
        cp src/processor/scoped_ptr.*h "$INCLUDE_DIRECTORY/processor"
        cp src/tools/linux/dump_syms/dump_syms "$BINARY_DIRECTORY"
    ;;
esac
mkdir -p stage/LICENSES
cp COPYING stage/LICENSES/google_breakpad.txt

pass

