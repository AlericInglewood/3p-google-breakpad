
# -*- cmake -*-

project(google_breakpad)


IF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(CMAKE_OSX_SYSROOT /Developer/SDKs/MacOSX10.4u.sdk)
    set(CMAKE_OSX_DEPLOYMENT_TARGET 10.4)
    set(CMAKE_XCODE_ATTRIBUTE_GCC_VERSION "4.0")
    set(CMAKE_OSX_ARCHITECTURES i386)
    set(CMAKE_CXX_COMPILER "g++-4.0")
    set(CMAKE_CXX_FLAGS "-m32")
    set(CMAKE_C_COMPILER "gcc-4.0")
    set(CMAKE_C_FLAGS "-m32")
    add_subdirectory("client/mac/handler")
ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")