#!/bin/bash

export NDK_ROOT=/Users/Drc15H/Library/Android/sdk/ndk/21.1.6352462 #这里配置先你的 NDK 路径
TOOLCHAIN=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64


function build_android
{

./configure \
--prefix=$PREFIX \
--enable-static \
--disable-shared \
--disable-doc \
--disable-programs \
--disable-everything \
--disable-avdevice \
--disable-avformat \
--disable-swscale \
--disable-postproc \
--disable-avfilter \
--disable-symver \
--disable-avresample \
--enable-swresample \
--enable-avutil \
--enable-avcodec \
--extra-ldexeflags=-pie \
--enable-decoder=h264 \
--cross-prefix=$CROSS_PREFIX \
--target-os=android \
--arch=$ARCH \
--cpu=$CPU \
--cc=$CC \
--cxx=$CXX \
--enable-cross-compile \
--sysroot=$SYSROOT \
--extra-cflags="-Os -fpic $OPTIMIZE_CFLAGS" \
--extra-ldflags="$ADDI_LDFLAGS"

make clean
make -j16
make install

echo "============================ build android arm64-v8a success =========================="

}

#arm64-v8a
ARCH=arm64
CPU=armv8-a
API=21
CC=$TOOLCHAIN/bin/aarch64-linux-android$API-clang
CXX=$TOOLCHAIN/bin/aarch64-linux-android$API-clang++
SYSROOT=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/sysroot
CROSS_PREFIX=$TOOLCHAIN/bin/aarch64-linux-android-
PREFIX=$(pwd)/android/$CPU
OPTIMIZE_CFLAGS="-march=$CPU"

build_android