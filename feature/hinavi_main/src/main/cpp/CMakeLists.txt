# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(myNpmLib)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    add_definitions(-D_DEBUG)
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)
find_library(dsm-lib libdevice_security_mode.z.so)

add_library(hinavi_main SHARED napi_init.cpp)
target_link_libraries(hinavi_main PUBLIC libace_napi.z.so libhilog_ndk.z.so ${dsm-lib} libdeviceinfo_ndk.z.so)
