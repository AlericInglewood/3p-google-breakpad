
# -*- cmake -*-

project(google_breakpad)

set(CMAKE_OSX_ARCHITECTURES i386)

IF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    add_subdirectory("client/mac/handler")
ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
