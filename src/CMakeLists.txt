# -*- cmake -*-
cmake_minimum_required(VERSION 2.8)

project(google_breakpad)

set(CMAKE_OSX_ARCHITECTURES i386)

IF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(CMAKE_OSX_DEPLOYMENT_TARGET 10.6)
    set(CMAKE_XCODE_ATTRIBUTE_GCC_VERSION "com.apple.compilers.llvmgcc42")
    set(CMAKE_OSX_ARCHITECTURES i386)
    set(CMAKE_CXX_COMPILER "g++-4.2")
    set(CMAKE_CXX_FLAGS "-m32")
    set(CMAKE_C_COMPILER "gcc-4.2")
    set(CMAKE_C_FLAGS "-m32")
    add_subdirectory("client/mac/handler")
ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
