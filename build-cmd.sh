#!/bin/sh

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

# load autobuild provided shell functions and variables
# first remap the autobuild env to fix the path for sickwin
if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

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
mkdir -p "$INCLUDE_DIRECTORY/common"

case "$AUTOBUILD_PLATFORM" in
    "windows")
        # patch vcproj generator to use Multi-Threaded DLL for +3 link karma
        #
        patch -p 1 < gyp.patch
        (
            cd src/client/windows
            ../../tools/gyp/gyp --no-circular-check -f msvs -G msvs-version=2005
        )
        
        load_vsvars
        
        devenv.com src/client/windows/breakpad_client.sln /Upgrade
        devenv.com src/tools/windows/dump_syms/dump_syms.vcproj /Upgrade

        devenv.com src/client/windows/breakpad_client.sln /build "release" /project exception_handler
        devenv.com src/client/windows/breakpad_client.sln /build "debug" /project exception_handler
        devenv.com src/client/windows/breakpad_client.sln /build "release" /project crash_generation_client
        devenv.com src/client/windows/breakpad_client.sln /build "debug"  /project crash_generation_client
        devenv.com src/client/windows/breakpad_client.sln /build "release"  /project common
        devenv.com src/client/windows/breakpad_client.sln /build "debug"  /project common

        #using devenv directly - buildconsole doesn't support building vs2010 vcxproj files directly, yet
        devenv.com src/tools/windows/dump_syms/dump_syms.vcxproj /build "release|win32" 

        mkdir -p "$INCLUDE_DIRECTORY/client/windows/"{common,crash_generation}
        mkdir -p "$INCLUDE_DIRECTORY/common/windows"
        mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
        mkdir -p "$INCLUDE_DIRECTORY/processor"

        cp ./src/client/windows/handler/exception_handler.h "$INCLUDE_DIRECTORY"
        cp ./src/client/windows/common/*.h "$INCLUDE_DIRECTORY/client/windows/common"
        cp ./src/common/windows/*.h "$INCLUDE_DIRECTORY/common/windows"
        cp ./src/client/windows/crash_generation/*.h "$INCLUDE_DIRECTORY/client/windows/crash_generation"
        cp ./src/google_breakpad/common/*.h "$INCLUDE_DIRECTORY/google_breakpad/common"
        cp ./src/client/windows/Debug/lib/*.lib "$LIBRARY_DIRECTORY_DEBUG"
        cp ./src/client/windows/Release/lib/*.lib "$LIBRARY_DIRECTORY_RELEASE"
        cp ./src/tools/windows/dump_syms/Release/dump_syms.exe "$BINARY_DIRECTORY"
        cp src/processor/scoped_ptr.h "$INCLUDE_DIRECTORY/processor/scoped_ptr.h"
        cp src/common/scoped_ptr.h "$INCLUDE_DIRECTORY/common/scoped_ptr.h"
    ;;
    darwin)
        (
            cd src/
            cmake -G Xcode CMakeLists.txt
            xcodebuild -arch i386 -project google_breakpad.xcodeproj -configuration Release
        )
        xcodebuild -arch i386 -project src/tools/mac/dump_syms/dump_syms.xcodeproj MACOSX_DEPLOYMENT_TARGET=10.6 -configuration Release
        mkdir -p "$INCLUDE_DIRECTORY/processor"
        mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
        mkdir -p "$INCLUDE_DIRECTORY/client/mac/crash_generation"
        mkdir -p "$INCLUDE_DIRECTORY/client/mac/crash_generation/common/mac"
        cp ./src/client/mac/handler/exception_handler.h "$INCLUDE_DIRECTORY"
        cp ./src/client/mac/crash_generation/crash_generation_client.h "$INCLUDE_DIRECTORY/client/mac/crash_generation"
        cp ./src/common/mac/MachIPC.h "$INCLUDE_DIRECTORY/client/mac/crash_generation/common/mac"
        cp ./src/client/mac/handler/Release/libexception_handler.dylib "$LIBRARY_DIRECTORY_RELEASE"
        cp ./src/tools/mac/dump_syms/build/Release/dump_syms "$BINARY_DIRECTORY"
        cp src/processor/scoped_ptr.h "$INCLUDE_DIRECTORY/processor/scoped_ptr.h"
        cp src/common/scoped_ptr.h "$INCLUDE_DIRECTORY/common/scoped_ptr.h"
    ;;
    linux)
        VIEWER_FLAGS="-m32 -fno-stack-protector"

	# Hack to force using g++ for CC as some of the code compiled as C uses namespaces...
	#
	if [[ -f /usr/bin/gcc-4.1 && -f /usr/bin/g++-4.1 ]] ; then
	   export CC=g++-4.1 -c99
	   export CXX=g++-4.1
	else
	   export CC="g++ -c99"
	   export CXX=g++
	fi

        ./configure --prefix="$(pwd)/stage" CFLAGS="$VIEWER_FLAGS" CXXFLAGS="$VIEWER_FLAGS" LDFLAGS=-m32
        make
        make -C src/tools/linux/dump_syms/ dump_syms
        make install
        mkdir -p "$INCLUDE_DIRECTORY/processor"
        mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/handler"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/crash_generation"
        cp -P stage/lib/libbreakpad*.a* "$LIBRARY_DIRECTORY_RELEASE"
        cp src/client/linux/handler/*.h "$INCLUDE_DIRECTORY"
		cp ./src/client/linux/handler/minidump_descriptor.h "$INCLUDE_DIRECTORY"
		cp ./src/common/using_std_string.h "$INCLUDE_DIRECTORY"
        cp src/client/linux/crash_generation/*.h "$INCLUDE_DIRECTORY/client/linux/crash_generation"
        cp src/tools/linux/dump_syms/dump_syms "$BINARY_DIRECTORY"
        cp src/processor/scoped_ptr.h "$INCLUDE_DIRECTORY/processor/scoped_ptr.h"
        cp src/common/scoped_ptr.h "$INCLUDE_DIRECTORY/common/scoped_ptr.h"
    ;;
esac
mkdir -p "$INCLUDE_DIRECTORY/common"
# yes, this looks dumb, no, it's not incorrect
mkdir -p stage/LICENSES
cp COPYING stage/LICENSES/google_breakpad.txt

pass

