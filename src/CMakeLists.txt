
# -*- cmake -*-

project(google_breakpad)


IF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    add_subdirectory("client/mac/handler")
ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")