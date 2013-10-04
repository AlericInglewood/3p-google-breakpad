#!/bin/sh

cd "`dirname "$0"`"
top="`pwd`"
stage="$top/stage"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="`cygpath -u $AUTOBUILD`"
fi

# load autbuild provided shell functions and variables
set +x
eval "`"$AUTOBUILD" source_environment`"
set -x

build_linux()
{
    prefix="$1"
    bits="$2"
    shift; shift

    VIEWER_FLAGS="-m$bits -fno-stack-protector"
    ./configure --prefix="$top/stage$prefix" --libdir="$top/stage$prefix/lib/release" --disable-processor CFLAGS="$VIEWER_FLAGS" CXXFLAGS="$VIEWER_FLAGS" LDFLAG="-m$bits"

    make
    make -C src/tools/linux/dump_syms/ dump_syms CXXFLAGS="-g3 -O2 -Wall -m$bits"
    make install

    INCLUDE_DIRECTORY="$stage$prefix/include/google_breakpad"
    mkdir -p "$INCLUDE_DIRECTORY"
    mkdir -p "$INCLUDE_DIRECTORY/client/linux/handler"
    mkdir -p "$INCLUDE_DIRECTORY/client/linux/crash_generation"
    mkdir -p "$INCLUDE_DIRECTORY/client/linux/minidump_writer"
    mkdir -p "$INCLUDE_DIRECTORY/client/linux/log"
    mkdir -p "$INCLUDE_DIRECTORY/common"
    mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
    mkdir -p "$INCLUDE_DIRECTORY/processor"
    mkdir -p "$INCLUDE_DIRECTORY/third_party/lss"

    # Replicate breakpad headers
    cp src/common/*.h "$INCLUDE_DIRECTORY/common"
    cp src/google_breakpad/common/*.h "$INCLUDE_DIRECTORY/google_breakpad/common"
    cp src/client/linux/crash_generation/*.h "$INCLUDE_DIRECTORY/client/linux/crash_generation"
    cp src/client/linux/handler/*.h "$INCLUDE_DIRECTORY/client/linux/handler"
    cp src/client/linux/minidump_writer/*.h "$INCLUDE_DIRECTORY/client/linux/minidump_writer"
    cp src/client/linux/log/*.h "$INCLUDE_DIRECTORY/client/linux/log"
    cp src/third_party/lss/*.h "$INCLUDE_DIRECTORY/third_party/lss"

    # And then cherry-pick some so they are found as used by the viewer
    cp src/common/using_std_string.h "$INCLUDE_DIRECTORY"
    cp src/client/linux/handler/exception_handler.h "$INCLUDE_DIRECTORY"
    cp src/client/linux/handler/exception_handler.h "$INCLUDE_DIRECTORY/google_breakpad/"
    cp src/client/linux/handler/minidump_descriptor.h "$INCLUDE_DIRECTORY"
    cp src/client/linux/handler/minidump_descriptor.h "$INCLUDE_DIRECTORY/google_breakpad/"
    cp src/processor/scoped_ptr.h "$INCLUDE_DIRECTORY/processor/scoped_ptr.h"
}

case "$AUTOBUILD_PLATFORM" in
    "windows")
        # patch vcproj generator to use Multi-Threaded DLL for +3 link karma
        #
	# modified gyp is checked in now...patch is in repo for reference
	#
        #patch -p 1 < gyp.patch
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
        devenv.com src/client/windows/breakpad_client.sln /build "release" /project crash_generation_server
        devenv.com src/client/windows/breakpad_client.sln /build "debug"  /project crash_generation_server
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
	    rm CMakeCache.txt
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
    "linux")
	build_linux /libraries/i686-linux 32
    ;;
    "linux64")
	build_linux /libraries/x86_64-linux 64
    ;;
esac

mkdir -p "$stage/LICENSES"
cp COPYING "$stage/LICENSES/google_breakpad.txt"

cd "$top"

pass

