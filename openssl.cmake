cmake_minimum_required(VERSION 3.25...3.31)

project(openssl_build LANGUAGES C)

set(OPENSSL_VERSION "1.0.2u")
set(SHA256 ecd0c6ffb493dd06707d38b14bb4d8c2288bb7033735606569d8f90f89669d16)
set(OPENSSL_URL "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz")

include(ExternalProject)

if(MSVC)
    set(MAKE_PROGRAM nmake -f ms\\\\nt.mak)
    set(OS_CONFIG_SETUP VC-WIN32)
    set(INSTALL_SW install)
else()
    set(MAKE_PROGRAM make -j8)
    set(INSTALL_SW install_sw)
    if(LINUX)
        # or linux-aarch64
        set(OS_CONFIG_SETUP linux-x86_64)
    elseif(APPLE)
        # NOTE: missing darwin-arm64 on CI
        set(OS_CONFIG_SETUP darwin64-x86_64-cc)
    else()
        message(FATAL_ERROR "OS is not supported")
    endif()
endif()

set(OPENSSL_BUILD_TYPE $<CONFIG>)
if($ENV{CI})
    set(OPENSSL_WRITE_LOG OFF)
else()
    set(OPENSSL_WRITE_LOG ON)
endif()

set(CONFIG_DEBUG_PREFIX)
if(CMAKE_BUILD_TYPE STREQUAL Debug)
    set(CONFIG_DEBUG_PREFIX debug-)
endif()

find_program(PERL_PROGRAM perl REQUIRED)

include(zlib.cmake)

ExternalProject_Add(
    openssl
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    DOWNLOAD_NO_PROGRESS TRUE
    PREFIX ${CMAKE_BINARY_DIR}
    BUILD_IN_SOURCE TRUE
    #--Download step--------------
    URL ${OPENSSL_URL}
    URL_HASH SHA256=${SHA256}
    #--Update/Patch step----------
    # see build/src/openssl/Configure
    #     build/src/openssl-stamp/openssl-patch-info.txt
    PATCH_COMMAND
        ${PERL_PROGRAM} -p -i.bak -e "s/[\\/-]WX//g" util/pl/VC-32.pl Configure shlib/win32.bat shlib/win32dll.bat
    #--Configure step-------------
    USES_TERMINAL_CONFIGURE TRUE
    # see build/src/openssl-build
    # and build/src/openssl-stamp
    # first:
    #     build/src/openssl-stamp/openssl-configure-Debug.cmake
    #     build/src/openssl-stamp/openssl-configure-Release.cmake
    #     build/src/openssl-stamp/openssl-configure-err.log
    #     build/src/openssl-stamp/openssl-configure-out.log
    # second:
    #     build/src/openssl-stamp/openssl-build-Debug.cmake
    #     build/src/openssl-stamp/openssl-build-Release.cmake
    #     build/src/openssl-stamp/openssl-build-err.log
    #     build/src/openssl-stamp/openssl-build-out.log
    # gen build/tmp/openssl-cfgcmd.txt
    CONFIGURE_COMMAND
        ${PERL_PROGRAM} Configure ${CONFIG_DEBUG_PREFIX}${OS_CONFIG_SETUP} no-asm no-hw no-krb5
        --prefix=${CMAKE_INSTALL_PREFIX}
    #--Build step-----------------
    USES_TERMINAL_BUILD TRUE
    BUILD_COMMAND ${MAKE_PROGRAM}
    #--Install step---------------
    USES_TERMINAL_INSTALL TRUE
    INSTALL_COMMAND ${MAKE_PROGRAM} ${INSTALL_SW}
    #--Logging -------------------
    LOG_MERGED_STDOUTERR TRUE
    LOG_DOWNLOAD OFF
    LOG_CONFIGURE ${OPENSSL_WRITE_LOG}
    LOG_BUILD ${OPENSSL_WRITE_LOG}
    LOG_INSTALL OFF
)

if(MSVC)
    ExternalProject_Add_Step(
        openssl
        generation
        COMMAND ${CMAKE_COMMAND} -E echo "Makefile generation"
        COMMAND cmd /C "cd && ms\\do_ms.bat"
        # XXX COMMAND /bin/sh -c "pwd && ls -l ms/do_ms.bat"
        COMMAND ${CMAKE_COMMAND} -E echo "... generation completed"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/src/openssl
        DEPENDEES configure
        DEPENDERS build
        USES_TERMINAL TRUE
    )
    ExternalProject_Add_Steptargets(openssl generation)
endif()

add_dependencies(openssl zlib1)
