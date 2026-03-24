#!/bin/bash
#
# Copyright (C) 2019 The Android Open Source Project
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

set -e  # 遇到错误立即退出，方便排查

# 基础配置（根据你的实际路径调整）
FFMPEG_VERSION="4.4.2"
FFMPEG_MODULE_PATH="/Users/Drc15H/GithubProjects/ExoPlayer/extensions/ffmpeg/src/main/jni/ffmpeg-${FFMPEG_VERSION}"
NDK_PATH="/Users/Drc15H/Library/Android/sdk/ndk/28.2.13676358"
HOST_PLATFORM="darwin-x86_64"
# NDK r26+ 不再提供 androideabi16 前缀的 clang，armv7 至少用 21
ARMV7_API=21
ARM64_API=24
# disable-everything 后按需追加（留空数组即可不启用）
ENABLED_VIDEO_DECODERS=("h264" "hevc")
# 常见音频容器；若不用 libavformat 读文件可改为 ()
ENABLED_DEMUXERS=(mp3 wav matroska flac ogg mov)
ENABLED_PROTOCOLS=(file pipe)
# 指定安装前缀（库文件会输出到该目录的 lib 下）
PREFIX_DIR="/Users/Drc15H/GithubProjects/ExoPlayer/extensions/ffmpeg/src/main/jni/ffmpeg-build"
# 自动获取CPU核心数（兼容macOS/Linux）
JOBS=$(nproc 2> /dev/null || sysctl -n hw.logicalcpu 2> /dev/null || echo 4)
echo "Using $JOBS jobs for make"

cd "${FFMPEG_MODULE_PATH}" || { echo "FFmpeg源码路径不存在！"; exit 1; }

TOOLCHAIN_PREFIX="${NDK_PATH}/toolchains/llvm/prebuilt/${HOST_PLATFORM}/bin"
if [[ ! -x "${TOOLCHAIN_PREFIX}/llvm-ar" ]]; then
  echo "NDK 工具链不存在: ${TOOLCHAIN_PREFIX}"
  exit 1
fi

mkdir -p "${PREFIX_DIR}/android-libs/armeabi-v7a" "${PREFIX_DIR}/android-libs/arm64-v8a"
for _abi_check in armeabi-v7a arm64-v8a; do
  _libdir="${PREFIX_DIR}/android-libs/${_abi_check}"
  if [[ -d "${_libdir}" ]] && [[ ! -w "${_libdir}" ]]; then
    echo "错误: 无写权限: ${_libdir}（常见于目录曾被 root 安装）。请执行: sudo chown -R \"\$(whoami)\" \"${PREFIX_DIR}\""
    exit 1
  fi
done

# --disable-everything 后组件全关，需显式打开库 + 解码器等。
# 音频解码：用 codec_desc（AUDIO）与 allcodecs.c 中 decoder 名求交，生成全部内置音频解码器开关。
# 若还要用 avformat 读本地文件，需协议 + demuxer（见上方 ENABLED_* 数组）。
#
# 静态库要链进 JNI 的 .so：必须生成 PIC，且勿与 Android 默认 -fPIE 混用，否则 lld 常见报错：
#   R_AARCH64_ADR_PREL_PG_HI21 cannot be used against symbol 'ff_cos_32'; recompile with -fPIC
# --enable-pic 会给 C/汇编加 -fPIC 与 -DPIC，使 aarch64 下 movrel 走 PIC 分支。
# -fno-pie 抵消 configure 对 android 自动加的 -fPIE，避免与「编入 .so」的静态库要求不一致。
# 另：已对 ffmpeg-4.4.2 打上游 movrelx 补丁（libavutil/aarch64/asm.S 等），对定义在其它 .o 里的
# 外部表（如 ff_sbr_noise_table、ff_cos_*）经 GOT 取址，否则 lld 仍会报 ADR_PREL_PG_HI21。
COMMON_OPTIONS="--target-os=android \
    --enable-static \
    --disable-shared \
    --enable-pic \
    --disable-doc \
    --disable-programs \
    --disable-everything \
    --disable-avdevice \
    --enable-avutil \
    --enable-avcodec \
    --enable-avformat \
    --disable-swscale \
    --disable-postproc \
    --disable-avfilter \
    --disable-symver \
    --disable-avresample \
    --enable-swresample \
    --extra-ldexeflags=-pie \
    --prefix=${PREFIX_DIR} \
    --nm=${TOOLCHAIN_PREFIX}/llvm-nm \
    --ar=${TOOLCHAIN_PREFIX}/llvm-ar \
    --ranlib=${TOOLCHAIN_PREFIX}/llvm-ranlib \
    --strip=${TOOLCHAIN_PREFIX}/llvm-strip"

CODEC_DESC="${FFMPEG_MODULE_PATH}/libavcodec/codec_desc.c"
ALLCODECS_C="${FFMPEG_MODULE_PATH}/libavcodec/allcodecs.c"
AUDIO_DECODERS_LIST="$(mktemp -t ffmpeg_audio_decoders.XXXXXX)"
trap '[[ -n "${AUDIO_DECODERS_LIST:-}" ]] && rm -f "${AUDIO_DECODERS_LIST}"' EXIT
comm -12 \
  <(awk '
    /\.type[ \t]*=[ \t]*AVMEDIA_TYPE_AUDIO,/ { a=1; next }
    a && /\.name[ \t]*=[ \t]*"/ {
      if (match($0, /"[^"]+"/)) print substr($0, RSTART+1, RLENGTH-2)
      a=0
    }
  ' "${CODEC_DESC}" | sort -u) \
  <(grep -oE 'ff_[a-zA-Z0-9_]+_decoder' "${ALLCODECS_C}" | sed 's/^ff_//;s/_decoder$//' | sort -u) \
  >"${AUDIO_DECODERS_LIST}"

while IFS= read -r decoder || [[ -n "${decoder}" ]]; do
  [[ -z "${decoder}" ]] && continue
  COMMON_OPTIONS="${COMMON_OPTIONS} --enable-decoder=${decoder}"
done <"${AUDIO_DECODERS_LIST}"

for decoder in "${ENABLED_VIDEO_DECODERS[@]}"; do
  [[ -n "${decoder}" ]] && COMMON_OPTIONS="${COMMON_OPTIONS} --enable-decoder=${decoder}"
done
for demuxer in "${ENABLED_DEMUXERS[@]}"; do
  [[ -n "${demuxer}" ]] && COMMON_OPTIONS="${COMMON_OPTIONS} --enable-demuxer=${demuxer}"
done
for proto in "${ENABLED_PROTOCOLS[@]}"; do
  [[ -n "${proto}" ]] && COMMON_OPTIONS="${COMMON_OPTIONS} --enable-protocol=${proto}"
done

# -------------------------- 1. 编译 armeabi-v7a --------------------------
echo "=== Compiling for armeabi-v7a ==="
./configure \
    --libdir="${PREFIX_DIR}/android-libs/armeabi-v7a" \
    --arch=arm \
    --cpu=armv7-a \
    --cross-prefix="${TOOLCHAIN_PREFIX}/armv7a-linux-androideabi${ARMV7_API}-" \
    --cc="${TOOLCHAIN_PREFIX}/armv7a-linux-androideabi${ARMV7_API}-clang" \
    --cxx="${TOOLCHAIN_PREFIX}/armv7a-linux-androideabi${ARMV7_API}-clang++" \
    --extra-cflags="-march=armv7-a -mfloat-abi=softfp -fPIC -O2 -fno-pie -fno-PIE" \
    --extra-ldflags="-Wl,--fix-cortex-a8" \
    ${COMMON_OPTIONS}

make -j$JOBS
make install-libs
make install-headers
make clean

# -------------------------- 2. 编译 arm64-v8a（核心修正） --------------------------
echo "=== Compiling for arm64-v8a ==="
./configure \
    --libdir="${PREFIX_DIR}/android-libs/arm64-v8a" \
    --arch=aarch64 \
    --cpu=armv8-a \
    --cross-prefix="${TOOLCHAIN_PREFIX}/aarch64-linux-android${ARM64_API}-" \
    --cc="${TOOLCHAIN_PREFIX}/aarch64-linux-android${ARM64_API}-clang" \
    --cxx="${TOOLCHAIN_PREFIX}/aarch64-linux-android${ARM64_API}-clang++" \
    --extra-cflags="-fPIC -O2 -fno-pie -fno-PIE" \
    --extra-cxxflags="-fPIC -O2 -fno-pie -fno-PIE" \
    --extra-ldflags="-fPIC" \
    ${COMMON_OPTIONS}

make -j$JOBS
make install-libs
make install-headers
make clean

echo "=== Compile completed! ==="
echo "  静态库: ${PREFIX_DIR}/android-libs/<abi>/ (libavcodec.a libavformat.a libavutil.a libswresample.a)"
echo "  头文件: ${PREFIX_DIR}/include/ (libavcodec libavformat libavutil libswresample 等)"



#FFMPEG_VERSION="4.3.6"
#FFMPEG_MODULE_PATH="/Users/Drc15H/GithubProjects/ExoPlayer/extensions/ffmpeg/src/main/jni/ffmpeg-${FFMPEG_VERSION}"
#NDK_PATH="/Users/Drc15H/Library/Android/sdk/ndk/21.1.6352462"
#HOST_PLATFORM="darwin-x86_64"
#ENABLED_DECODERS="h264 hevc"
#PREFIX_DIF="/Users/Drc15H/GithubProjects/ExoPlayer/extensions/ffmpeg/src/main/jni/ffmpeg"
#JOBS=$(nproc 2> /dev/null || sysctl -n hw.ncpu 2> /dev/null || echo 4)
#echo "Using $JOBS jobs for make"
#COMMON_OPTIONS="
#    --target-os=android
#    --enable-static
#    --disable-shared
#    --disable-doc
#    --disable-programs
#    --disable-everything
#    --disable-avdevice
#    --disable-avformat
#    --disable-swscale
#    --disable-postproc
#    --disable-avfilter
#    --disable-symver
#    --disable-avresample
#    --enable-swresample
#    --enable-avutil
#    --enable-avcodec
#    --extra-ldexeflags=-pie
#    "
#TOOLCHAIN_PREFIX="${NDK_PATH}/toolchains/llvm/prebuilt/${HOST_PLATFORM}/bin"
#IFS=" " read -ra decoders <<< $ENABLED_DECODERS
#for decoder in "${decoders[@]}"
#do
#    COMMON_OPTIONS="${COMMON_OPTIONS} --enable-decoder=${decoder}"
#done
#cd "${FFMPEG_MODULE_PATH}"
#./configure \
#    --libdir="${PREFIX_DIF}/android-libs/armeabi-v7a" \
#    --incdir="${PREFIX_DIF}" \
#    --arch=arm \
#    --cpu=armv7-a \
#    --cross-prefix="${TOOLCHAIN_PREFIX}/armv7a-linux-androideabi16-" \
#    --nm="${TOOLCHAIN_PREFIX}/llvm-nm" \
#    --ar="${TOOLCHAIN_PREFIX}/llvm-ar" \
#    --ranlib="${TOOLCHAIN_PREFIX}/llvm-ranlib" \
#    --strip="${TOOLCHAIN_PREFIX}/llvm-strip" \
#    --extra-cflags="-march=armv7-a -mfloat-abi=softfp" \
#    --extra-ldflags="-Wl,--fix-cortex-a8" \
#    ${COMMON_OPTIONS}
#make -j$JOBS
#make install
#make clean
#./configure \
#    --libdir="${PREFIX_DIF}/android-libs/arm64-v8a" \
#    --incdir="${PREFIX_DIF}" \
#    --arch=aarch64 \
#    --cpu=armv8-a \
#    --cross-prefix="${TOOLCHAIN_PREFIX}/aarch64-linux-android21-" \
#    --nm="${TOOLCHAIN_PREFIX}/llvm-nm" \
#    --ar="${TOOLCHAIN_PREFIX}/llvm-ar" \
#    --ranlib="${TOOLCHAIN_PREFIX}/llvm-ranlib" \
#    --strip="${TOOLCHAIN_PREFIX}/llvm-strip" \
#    ${COMMON_OPTIONS}
#make -j$JOBS
#make install
#make clean




#FFMPEG_VERSION="4.3.6"
#FFMPEG_MODULE_PATH="/Users/Drc15H/GithubProjects/ExoPlayer/extensions/ffmpeg/src/main/jni/ffmpeg-${FFMPEG_VERSION}"
#NDK_PATH="/Users/Drc15H/Library/Android/sdk/ndk/21.1.6352462"
#HOST_PLATFORM="darwin-x86_64"
#ENABLED_DECODERS="h264 hevc"
#PREFIX_DIF="/Users/Drc15H/GithubProjects/ExoPlayer/extensions/ffmpeg/src/main/jni/ffmpeg"
#JOBS=$(nproc 2> /dev/null || sysctl -n hw.ncpu 2> /dev/null || echo 4)
#echo "Using $JOBS jobs for make"
#COMMON_OPTIONS="
#    --target-os=android
#    --enable-static
#    --disable-shared
#    --disable-doc
#    --disable-programs
#    --disable-everything
#    --disable-avdevice
#    --disable-avformat
#    --disable-swscale
#    --disable-postproc
#    --disable-avfilter
#    --disable-symver
#    --disable-avresample
#    --enable-swresample
#    --enable-avutil
#    --enable-avcodec
#    --extra-ldexeflags=-pie
#    "
#TOOLCHAIN_PREFIX="${NDK_PATH}/toolchains/llvm/prebuilt/${HOST_PLATFORM}/bin"
#IFS=" " read -ra decoders <<< $ENABLED_DECODERS
#for decoder in "${decoders[@]}"
#do
#    COMMON_OPTIONS="${COMMON_OPTIONS} --enable-decoder=${decoder}"
#done
#cd "${FFMPEG_MODULE_PATH}"
#./configure \
#    --libdir="${PREFIX_DIF}/android-libs/armeabi-v7a" \
#    --incdir="${PREFIX_DIF}" \
#    --arch=arm \
#    --cpu=armv7-a \
#    --cross-prefix="${TOOLCHAIN_PREFIX}/armv7a-linux-androideabi16-" \
#    --nm="${TOOLCHAIN_PREFIX}/llvm-nm" \
#    --ar="${TOOLCHAIN_PREFIX}/llvm-ar" \
#    --ranlib="${TOOLCHAIN_PREFIX}/llvm-ranlib" \
#    --strip="${TOOLCHAIN_PREFIX}/llvm-strip" \
#    --extra-cflags="-march=armv7-a -mfloat-abi=softfp" \
#    --extra-ldflags="-Wl,--fix-cortex-a8" \
#    ${COMMON_OPTIONS}
#make -j$JOBS
#make install
#make clean
#./configure \
#    --libdir="${PREFIX_DIF}/android-libs/arm64-v8a" \
#    --incdir="${PREFIX_DIF}" \
#    --arch=aarch64 \
#    --cpu=armv8-a \
#    --cross-prefix="${TOOLCHAIN_PREFIX}/aarch64-linux-android21-" \
#    --nm="${TOOLCHAIN_PREFIX}/llvm-nm" \
#    --ar="${TOOLCHAIN_PREFIX}/llvm-ar" \
#    --ranlib="${TOOLCHAIN_PREFIX}/llvm-ranlib" \
#    --strip="${TOOLCHAIN_PREFIX}/llvm-strip" \
#    ${COMMON_OPTIONS}
#make -j$JOBS
#make install
#make clean




#FFMPEG_VERSION="4.3.6"
#FFMPEG_MODULE_PATH="/Users/Drc15H/GithubProjects/ExoPlayer/extensions/ffmpeg/src/main/jni/ffmpeg-${FFMPEG_VERSION}"
#NDK_PATH="/Users/Drc15H/Library/Android/sdk/ndk/21.1.6352462"
#HOST_PLATFORM="darwin-x86_64"
#ENABLED_DECODERS="h264 hevc"
#PREFIX_DIF="/Users/Drc15H/GithubProjects/ExoPlayer/extensions/ffmpeg/src/main/jni/ffmpeg"
#JOBS=$(nproc 2> /dev/null || sysctl -n hw.ncpu 2> /dev/null || echo 4)
#echo "Using $JOBS jobs for make"
#COMMON_OPTIONS="
#    --target-os=android
#    --enable-static
#    --disable-shared
#    --disable-doc
#    --disable-programs
#    --disable-everything
#    --disable-avdevice
#    --disable-avformat
#    --disable-swscale
#    --disable-postproc
#    --disable-avfilter
#    --disable-symver
#    --disable-avresample
#    --enable-swresample
#    --enable-avutil
#    --enable-avcodec
#    --extra-ldexeflags=-pie
#    "
#TOOLCHAIN_PREFIX="${NDK_PATH}/toolchains/llvm/prebuilt/${HOST_PLATFORM}/bin"
#IFS=" " read -ra decoders <<< $ENABLED_DECODERS
#for decoder in "${decoders[@]}"
#do
#    COMMON_OPTIONS="${COMMON_OPTIONS} --enable-decoder=${decoder}"
#done
#cd "${FFMPEG_MODULE_PATH}"
#./configure \
#    --libdir="${PREFIX_DIF}/android-libs/armeabi-v7a" \
#    --incdir="${PREFIX_DIF}" \
#    --arch=arm \
#    --cpu=armv7-a \
#    --cross-prefix="${TOOLCHAIN_PREFIX}/armv7a-linux-androideabi16-" \
#    --nm="${TOOLCHAIN_PREFIX}/llvm-nm" \
#    --ar="${TOOLCHAIN_PREFIX}/llvm-ar" \
#    --ranlib="${TOOLCHAIN_PREFIX}/llvm-ranlib" \
#    --strip="${TOOLCHAIN_PREFIX}/llvm-strip" \
#    --extra-cflags="-march=armv7-a -mfloat-abi=softfp" \
#    --extra-ldflags="-Wl,--fix-cortex-a8" \
#    ${COMMON_OPTIONS}
#make -j$JOBS
#make install
#make clean
#./configure \
#    --libdir="${PREFIX_DIF}/android-libs/arm64-v8a" \
#    --incdir="${PREFIX_DIF}" \
#    --arch=aarch64 \
#    --cpu=armv8-a \
#    --cross-prefix="${TOOLCHAIN_PREFIX}/aarch64-linux-android21-" \
#    --nm="${TOOLCHAIN_PREFIX}/llvm-nm" \
#    --ar="${TOOLCHAIN_PREFIX}/llvm-ar" \
#    --ranlib="${TOOLCHAIN_PREFIX}/llvm-ranlib" \
#    --strip="${TOOLCHAIN_PREFIX}/llvm-strip" \
#    ${COMMON_OPTIONS}
#make -j$JOBS
#make install
#make clean

