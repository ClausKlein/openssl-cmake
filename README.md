# Build OpenSSL with cmake ExternalProject modules

## Usage:

    cmake -B build -S . -G Ninja -D CMAKE_BUILD_TYPE=Debug -D CMAKE_INSTALL_PREFIX=/tmp/install
    ninja -C build
    ctest --test-dir build
    cmake -B build -S . -G Ninja -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/tmp/install
    ninja -C build
    ctest --test-dir build

