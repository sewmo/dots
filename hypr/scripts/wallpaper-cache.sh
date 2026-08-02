#!/bin/bash
set -euo pipefail

WALL_DIR="$HOME/Wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-picker"

THUMB_WIDTH=250
THUMB_HEIGHT=141

mkdir -p "$CACHE_DIR"

find "$WALL_DIR" -type f \
    \( \
        -iname "*.png" \
        -o -iname "*.jpg" \
        -o -iname "*.jpeg" \
        -o -iname "*.mp4" \
    \) |
while read -r file; do

    # Preserve directory structure inside the cache.
    rel="${file#$WALL_DIR/}"
    thumb="$CACHE_DIR/${rel}.thumb.png"

    mkdir -p "$(dirname "$thumb")"

    # Skip up-to-date thumbnails.
    if [[ -f "$thumb" && "$thumb" -nt "$file" ]]; then
        continue
    fi

    echo "Generating: $rel"

    case "${file##*.}" in
        mp4|MP4)
            ffmpeg -y \
                -loglevel error \
                -i "$file" \
                -frames:v 1 \
                -vf "scale=${THUMB_WIDTH}:${THUMB_HEIGHT}:force_original_aspect_ratio=increase,crop=${THUMB_WIDTH}:${THUMB_HEIGHT}" \
                "$thumb"
            ;;

        *)
            magick "$file" \
                -thumbnail "${THUMB_WIDTH}x${THUMB_HEIGHT}^" \
                -gravity center \
                -extent "${THUMB_WIDTH}x${THUMB_HEIGHT}" \
                "$thumb"
            ;;
    esac
done

echo "Thumbnail cache updated."
