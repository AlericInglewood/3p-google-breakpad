
# -*- cmake -*-

find_library(FOUNDATION_FRAMEWORK NAMES Foundation)

include_directories(
    ${PROJECT_SOURCE_DIR}/common
    ${PROJECT_SOURCE_DIR}/common/mac
    ${PROJECT_SOURCE_DIR}/client
    ${PROJECT_SOURCE_DIR}/client/mac/handler
    ${PROJECT_SOURCE_DIR}
    )


set(exception_handler_SOURCE_FILES
    ${PROJECT_SOURCE_DIR}/client/mac/handler/breakpad_nlist_64.cc
    ${PROJECT_SOURCE_DIR}/client/mac/handler/dynamic_images.cc
    ${PROJECT_SOURCE_DIR}/client/mac/handler/exception_handler.cc
    ${PROJECT_SOURCE_DIR}/client/mac/handler/minidump_generator.cc
    ${PROJECT_SOURCE_DIR}/client/minidump_file_writer.cc
    ${PROJECT_SOURCE_DIR}/common/convert_UTF.c
    ${PROJECT_SOURCE_DIR}/common/string_conversion.cc
    ${PROJECT_SOURCE_DIR}/common/mac/file_id.cc
    ${PROJECT_SOURCE_DIR}/common/mac/macho_id.cc
    ${PROJECT_SOURCE_DIR}/common/mac/macho_utilities.cc
    ${PROJECT_SOURCE_DIR}/common/mac/macho_walker.cc
    ${PROJECT_SOURCE_DIR}/common/mac/string_utilities.cc
    )

set(exception_handler_HEADER_FILES
    exception_handler.h
    )

set_source_files_properties(${exception_handler_HEADER_FILES}
                            PROPERTIES HEADER_FILE_ONLY TRUE)

list(APPEND exception_handler_SOURCE_FILES ${exception_handler_HEADER_FILES})

add_library (exception_handler SHARED ${exception_handler_SOURCE_FILES})

set_target_properties(exception_handler PROPERTIES
    BUILD_WITH_INSTALL_RPATH 1
    INSTALL_NAME_DIR "@executable_path/../Resources"
    )

target_link_libraries(
    exception_handler
    crypto
    ${FOUNDATION_FRAMEWORK}
    )
