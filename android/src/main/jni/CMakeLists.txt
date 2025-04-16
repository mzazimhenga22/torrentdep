cmake_minimum_required(VERSION 3.10.2)

project(torrent_handler)

# Add the JNI wrapper source file
add_library(torrent_handler SHARED torrent_handler.cpp)

# Locate the NDK sysroot for JNI headers
if(DEFINED ANDROID_NDK)
    include_directories(${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include)
    include_directories(${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/android)
endif()

# Include Boost headers
include_directories($ENV{BOOST_ROOT})

# Include libtorrent headers (relative path)
include_directories(${CMAKE_SOURCE_DIR}/../../../../libtorrent/include)

# Link against the prebuilt libtorrent-rasterbar library
add_library(libtorrent-rasterbar SHARED IMPORTED)
set_target_properties(libtorrent-rasterbar PROPERTIES IMPORTED_LOCATION
    ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libtorrent-rasterbar.so)

# Link the JNI wrapper with libtorrent-rasterbar and Android log library
target_link_libraries(torrent_handler libtorrent-rasterbar log)