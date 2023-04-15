#!/usr/bin/env bash
set -e

OUTPUT_BASENAME=$(basename "$2")
objcopy --only-keep-debug "$1" "$OUTPUT_BASENAME"
strip "$1"
objcopy --add-gnu-debuglink="$OUTPUT_BASENAME" "$1"
mv -f "$OUTPUT_BASENAME" "$2"
