cmake_minimum_required(VERSION 3.27...3.31)

project(openssl_build LANGUAGES C)

set(OPENSSL_VERSION "1.0.2u")
set(SHA256 ecd0c6ffb493dd06707d38b14bb4d8c2288bb7033735606569d8f90f89669d16)
set(OPENSSL_URL "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz")

include(ExternalProject)

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

if(MSVC)
    set(MAKE_PROGRAM nmake)
    set(OS_CONFIG_SETUP VC-WIN32)
else()
    set(MAKE_PROGRAM make -j8)
    if(LINUX)
        set(OS_CONFIG_SETUP linux-x86_64)
    elseif(APPLE)
        set(OS_CONFIG_SETUP darwin64-x86_64-cc)
    else()
        message(FATAL_ERROR "OS is not supported")
    endif()
endif()

find_program(PERL_PROGRAM perl REQUIRED)

include(zlib.cmake)

ExternalProject_Add(
    openssl
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    PREFIX ${CMAKE_BINARY_DIR}
    #--Download step--------------
    URL ${OPENSSL_URL}
    URL_HASH SHA256=${SHA256}
    #--Update/Patch step----------
    #--Configure step-------------
    USES_TERMINAL_CONFIGURE TRUE
    # see build/src/openssl/Configure
    # and build/src/openssl-stamp/openssl-configure-Debug.cmake
    #     build/src/openssl-stamp/openssl-configure-err.log
    #     build/src/openssl-stamp/openssl-configure-out.log
    # FIXME: --no-shared # XXX --static # TODO: depends on BUILD_SHARED_LIBS
    CONFIGURE_COMMAND
        cd <SOURCE_DIR> && ${PERL_PROGRAM} Configure ${CONFIG_DEBUG_PREFIX}${OS_CONFIG_SETUP} no-asm no-hw no-krb5
        --prefix=${CMAKE_INSTALL_PREFIX}
    ### # --openssldir=${CMAKE_INSTALL_PREFIX}/etc/ssl #
    # XXX && ms\\\\do_nt.bat
    # linux-aarch64
    #--Build step-----------------
    USES_TERMINAL_BUILD TRUE
    BUILD_COMMAND
        ${MAKE_PROGRAM} -C <SOURCE_DIR> # XXX -f ms\\\\nt.mak
    #--Install step---------------
    USES_TERMINAL_INSTALL TRUE
    INSTALL_COMMAND
        ${MAKE_PROGRAM} -C <SOURCE_DIR> # XXX -f ms\\\\nt.mak install
    #--Logging -------------------
    LOG_DOWNLOAD OFF
    # LOG_CONFIGURE ${OPENSSL_WRITE_LOG}
    LOG_BUILD ${OPENSSL_WRITE_LOG}
    LOG_INSTALL OFF
)

add_dependencies(openssl zlib1)
