#
# Copyright 2021 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

cmake_minimum_required(VERSION 3.18.1 FATAL_ERROR)

# Enable C++11 features.
set(CMAKE_CXX_STANDARD 11)

project(libffmpegJNI C CXX)

# Additional flags needed for "arm64-v8a" from NDK 23.1.7779620 and above.
# See https://github.com/google/ExoPlayer/issues/9933#issuecomment-1029775358.
if(${ANDROID_ABI} MATCHES "arm64-v8a")
    #CXXFLAGS是C++编译器的编译选项
    set(CMAKE_CXX_FLAGS "-Wl,-Bsymbolic")
endif()

#设置变量
set(ffmpeg_location "${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg")
set(ffmpeg_binaries "${ffmpeg_location}/android-libs/${ANDROID_ABI}")

foreach(ffmpeg_lib avutil swresample avcodec)
    set(ffmpeg_lib_filename lib${ffmpeg_lib}.a)
    set(ffmpeg_lib_file_path ${ffmpeg_binaries}/${ffmpeg_lib_filename})
    #导入外部的静态库
    add_library(
            ${ffmpeg_lib}
            STATIC
            #An IMPORTED library target references a library file located outside the project. No rules are generated to build it, and the IMPORTED target property is True. The target name has scope in the directory in which it is created and below, but the GLOBAL option extends visibility. It may be referenced like any target built within the project. IMPORTED libraries are useful for convenient reference from commands like target_link_libraries(). Details about the imported library are specified by setting properties whose names begin in IMPORTED_ and INTERFACE_.
            #导入静态库
            IMPORTED)
    set_target_properties(
            ${ffmpeg_lib} PROPERTIES
            IMPORTED_LOCATION #Full path to the main file on disk for an IMPORTED target. For STATIC libraries and modules this is the location of the library or module.
            ${ffmpeg_lib_file_path})
endforeach()

#用于设置包含的目录，这些设定的目录将被编译器用来查找 include 文件
include_directories(${ffmpeg_location})
find_library(android_log_lib log)

#编译出一个名为libffmpegJNI.so的动态库
add_library(ffmpegJNI
            SHARED
            ffmpeg_jni.cc)



#设置target需要链接的库
target_link_libraries(
        #目标库
        ffmpegJNI
        #目标库需要链接的库
        PRIVATE android
        PRIVATE swresample
        PRIVATE avcodec
        PRIVATE avutil
        PRIVATE ${android_log_lib}
        PRIVATE z)
