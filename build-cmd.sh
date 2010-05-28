#!/bin/sh

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
        INCDIR=stage/libraries/include/google_breakpad
        mkdir -p stage/libraries/i686-win32/lib/debug
        mkdir -p stage/libraries/i686-win32/lib/release
        mkdir -p $INCDIR
        mkdir -p $INCDIR/client/windows/{common,crash_generation}
        mkdir -p $INCDIR/common/windows
        mkdir -p $INCDIR/google_breakpad/common
        mkdir -p $INCDIR/processor
        mkdir -p stage/libraries/i686-win32/bin
        cp ./src/client/windows/handler/exception_handler.h $INCDIR
        cp src/client/windows/common/*.h $INCDIR/client/windows/common
        cp src/common/windows/*.h $INCDIR/common/windows
        cp src/client/windows/crash_generation/*.h $INCDIR/client/windows/crash_generation
        cp src/google_breakpad/common/*.h $INCDIR/google_breakpad/common
        cp src/processor/scoped_ptr.*h $INCDIR/processor
        cp ./src/client/windows/Debug/lib/*.lib ./stage/libraries/i686-win32/lib/debug
        cp ./src/client/windows/Release/lib/*.lib ./stage/libraries/i686-win32/lib/release
        cp ./src/tools/windows/dump_syms/Release/dump_syms.exe ./stage/libraries/i686-win32/bin
    ;;
    darwin)
        (
            cd src/
            cmake -G Xcode CMakeLists.txt
            xcodebuild -project google_breakpad.xcodeproj GCC_VERSION=4.0 MACOSX_DEPLOYMENT_TARGET=10.4 -sdk macosx10.4 -configuration Release
        )
		# *TODO - fix the release build of the dump_syms tool
        xcodebuild -project src/tools/mac/dump_syms/dump_syms.xcodeproj GCC_VERSION=4.0 MACOSX_DEPLOYMENT_TARGET=10.4 -sdk macosx10.4 -configuration Debug
        mkdir -p stage/libraries/universal-darwin/lib_release
        mkdir -p stage/libraries/universal-darwin/bin
        mkdir -p stage/libraries/include/google_breakpad
        cp ./src/client/mac/handler/exception_handler.h ./stage/libraries/include/google_breakpad
        cp ./src/client/mac/handler/Release/libexception_handler.dylib ./stage/libraries/universal-darwin/lib_release
        cp ./src/tools/mac/dump_syms/build/Debug/dump_syms ./stage/libraries/universal-darwin/bin
    ;;
    linux)
        VIEWER_FLAGS="-m32 -fno-stack-protector"
        ./configure --prefix="$(pwd)/stage" CFLAGS="$VIEWER_FLAGS" CXXFLAGS="$VIEWER_FLAGS" LDFLAGS=-m32
        make
        make -C src/tools/linux/dump_syms/ dump_syms
        make install
        INCDIR=stage/libraries/include/google_breakpad
        LIBDIR=stage/libraries/i686-linux/lib_release_client
        BINDIR=stage/libraries/i686-linux/bin
        mkdir -p $LIBDIR
        mkdir -p $INCDIR/client/linux/{handler,crash_generation}
        mkdir -p $INCDIR/processor
        mkdir -p $BINDIR
        cp -P stage/lib/libbreakpad*.so* $LIBDIR
        cp src/client/linux/handler/*.h $INCDIR
        cp src/client/linux/crash_generation/*.h $INCDIR/client/linux/crash_generation
        cp src/processor/scoped_ptr.*h $INCDIR/processor
        cp src/tools/linux/dump_syms/dump_syms "$BINDIR"
    ;;
esac
mkdir -p stage/LICENSES
cp COPYING stage/LICENSES/google_breakpad.txt

pass

