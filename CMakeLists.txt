cmake_minimum_required(VERSION 3.27...3.31)

project(OpenSSL_ExternalProject LANGUAGES C)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "Forced!" FORCE)

if(NOT CMAKE_C_STANDARD)
    set(CMAKE_C_STANDARD 11)
    set(CMAKE_C_STANDARD_REQUIRED YES)
    set(CMAKE_C_EXTENSIONS NO)
endif()

if(NOT CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
endif()

set(CMAKE_SKIP_TEST_ALL_DEPENDENCY NO)
enable_testing()

include(openssl.cmake)

# Optionally, add OpenSSL include and library directories for other targets
set(OPENSSL_INCLUDE_DIR ${CMAKE_INSTALL_PREFIX}/include)
if(LINUX)
    set(OPENSSL_LIB_DIR ${CMAKE_INSTALL_PREFIX}/lib64)
else()
    set(OPENSSL_LIB_DIR ${CMAKE_INSTALL_PREFIX}/lib)
endif()

# Display helpful messages
message(STATUS "FIND_LIBRARY_USE_LIB64_PATHS: ${FIND_LIBRARY_USE_LIB64_PATHS}")
message(STATUS "CMAKE_LIBRARY_ARCHITECTURE: ${CMAKE_LIBRARY_ARCHITECTURE}")
message(STATUS "CMAKE_LINK_LIBRARY_SUFFIX: ${CMAKE_LINK_LIBRARY_SUFFIX}")
message(STATUS "OpenSSL will be installed to: ${OPENSSL_INSTALL_DIR}")
message(STATUS "Include directory: ${OPENSSL_INCLUDE_DIR}")
message(STATUS "Library directory: ${OPENSSL_LIB_DIR}")

if(UNIX AND NOT CMAKE_LINK_LIBRARY_SUFFIX)
    set(_CMAKE_LINK_LIBRARY_SUFFIX ".a")
else()
    set(_CMAKE_LINK_LIBRARY_SUFFIX ${CMAKE_LINK_LIBRARY_SUFFIX})
endif()

set(ZLIB_DEBUG_POSTFIX)
if(CMAKE_BUILD_TYPE STREQUAL Debug)
    set(ZLIB_DEBUG_POSTFIX "d")
endif()
set(ZLIB_LINK_LIBRARIES z${ZLIB_DEBUG_POSTFIX})

set(OPENSSL_LINK_LIBRARIES)
if(MSVC)
    set(OPENSSL_LINK_LIBRARIES "ws2_32.lib;gdi32.lib;advapi32.lib;crypt32.lib;user32.lib")
    set(ZLIB_LINK_LIBRARIES zlib${ZLIB_DEBUG_POSTFIX})
    set(OPENSSL_LIB_SSL ssleay32)
    set(OPENSSL_LIB_CRYPTO libeay32)
else()
    set(OPENSSL_LIB_SSL ssl)
    set(OPENSSL_LIB_CRYPTO crypto)
    set(OPENSSL_LIBRARY_PREFIX lib)
endif()

if(UNIX)
    add_executable(my_app test.c easy-tls.c)
else()
    add_executable(my_app main.c)
endif()
target_include_directories(my_app PRIVATE ${OPENSSL_INCLUDE_DIR})
target_link_directories(my_app PRIVATE ${OPENSSL_LIB_DIR})
target_link_libraries(
    my_app
    PRIVATE
        ${OPENSSL_LIB_SSL}${ZLIB_DEBUG_POSTFIX}
        ${OPENSSL_LIB_CRYPTO}${ZLIB_DEBUG_POSTFIX}
        ${OPENSSL_LINK_LIBRARIES}
        ${ZLIB_LINK_LIBRARIES}
)
add_dependencies(my_app openssl)
add_test(NAME my-app-h COMMAND my_app -h)

# Create a target that depends on the OpenSSL build
add_custom_target(openssl_build ALL DEPENDS openssl)

if(ZLIB_DEBUG_POSTFIX)
    add_custom_command(
        TARGET openssl
        POST_BUILD
        COMMAND
            ${CMAKE_COMMAND} -E copy_if_different ${OPENSSL_LIBRARY_PREFIX}${OPENSSL_LIB_SSL}${_CMAKE_LINK_LIBRARY_SUFFIX}
            ${OPENSSL_LIBRARY_PREFIX}${OPENSSL_LIB_SSL}${ZLIB_DEBUG_POSTFIX}${_CMAKE_LINK_LIBRARY_SUFFIX}
        COMMAND
            ${CMAKE_COMMAND} -E copy_if_different
            ${OPENSSL_LIBRARY_PREFIX}${OPENSSL_LIB_CRYPTO}${_CMAKE_LINK_LIBRARY_SUFFIX}
            ${OPENSSL_LIBRARY_PREFIX}${OPENSSL_LIB_CRYPTO}${ZLIB_DEBUG_POSTFIX}${_CMAKE_LINK_LIBRARY_SUFFIX}
        VERBATIM
        WORKING_DIRECTORY ${OPENSSL_LIB_DIR}
    )
endif()

########
return()
########

# test if the targets are usable from the install directory
add_test(
    NAME find-package-test
    COMMAND
        ${CMAKE_CTEST_COMMAND}
        # --verbose
        --output-on-failure -C $<CONFIG> --build-and-test #
        "${CMAKE_CURRENT_SOURCE_DIR}/test-FindOpenSSL" "${CMAKE_CURRENT_BINARY_DIR}/find-package-test" #
        --build-generator ${CMAKE_GENERATOR} #
        --build-makeprogram ${CMAKE_MAKE_PROGRAM} #
        --build-options #
        "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}" #
        "-DCMAKE_C_STANDARD=${CMAKE_C_STANDARD}" #
        "-DCMAKE_BUILD_TYPE=$<CONFIG>" #
        "-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}" #
        "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
)
