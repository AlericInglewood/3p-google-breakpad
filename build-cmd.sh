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
        mkdir -p stage/libraries/i686-win32/lib/debug
        mkdir -p stage/libraries/i686-win32/lib/release
        mkdir -p stage/libraries/include
        cp ./src/client/windows/handler/exception_handler.h ./stage/libraries/include
        cp ./src/client/windows/Debug/lib/exception_handler.lib ./stage/libraries/i686-win32/lib/debug
        cp ./src/client/windows/Release/lib/exception_handler.lib ./stage/libraries/i686-win32/lib/release
    ;;
    darwin)
        (
            cd src/
            cmake CMakeLists.txt
            make
        )
        mkdir -p stage/libraries/universal-darwin/lib_release
        mkdir -p stage/libraries/include
        cp ./src/client/mac/handler/exception_handler.h ./stage/libraries/include
        cp ./src/client/mac/handler/libexception_handler.dylib ./stage/libraries/universal-darwin/lib_release
    ;;
    linux)
        ./configure --prefix="$(pwd)/stage"
        make
        make install
    ;;
esac
mkdir -p stage/LICENSES
cp COPYING stage/LICENSES/google_breakpad.txt

pass

