#!/bin/bash

ENABLED_DECODERS="h264 hevc"

COMMON_OPTIONS="
    --target-os=android
    --enable-static
    "

IFS=" " read -ra decoders <<< $ENABLED_DECODERS
for decoder in "${decoders[@]}"
do
    COMMON_OPTIONS="${COMMON_OPTIONS} --enable-decoder=${decoder}"
done

echo $COMMON_OPTIONS