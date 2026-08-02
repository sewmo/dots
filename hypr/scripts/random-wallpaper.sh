#!/bin/bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

# Variables
WALL_DIR="$HOME/Wallpapers"
TMP="/tmp/wall_thumb.png"

# Retrieve the wallpaper choice by picking a random path. The 'sed' command removes the beginning of the path.
choice=$(find "$WALL_DIR" -type f \
\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.mp4" \) \
| sort | sed "s|$WALL_DIR/||" \
| shuf -n 1)

# Exit if no choice selected. The '-z' checks if the string length is zero.
if [ -z "$choice" ]; then
  exit 1
fi

FILE="$WALL_DIR/$choice"

# Kill any existing mpvpaper processes. The '|| true' means if 'pkill' fails, run true, which doesn't make the script exit.
pkill mpvpaper || true

# Check the file type, with a switch statement.
case "${FILE##*.}" in

  # File type is image.
  png|PNG|jpg|JPG|jpeg|JPEG)

    # Run awww to set the wallpaper with transitions.
    awww img "$FILE" \
      --transition-type grow \
      --transition-duration 1

    # Run wal to extract colors from the wallpaper to '.cache/wal'
    wal -i "$FILE" -n -q

  ;;

  # File type is video.
  mp4|MP4)

    # Extracts one frame.
    ffmpeg -y -i "$FILE" \
      -frames:v 1 \
      "$TMP" \
      >/dev/null 2>&1

    # Shows the frame immediately, otherwise the screen would go briefly black while 'mpvpaper' starts.
    awww img "$TMP"

    wal -i "$TMP"

    while read monitor; do
      mpvpaper -o "--loop --hwdec=auto-safe --no-audio" \
        "$monitor" "$FILE" &
    done < <(
      hyprctl monitors -j | jq -r '.[].name'
    )

  ;;
esac 

# Reload colors for various applications.
nvim --headless "+LushwalCompile" +q
pkill waybar; waybar >/dev/null 2>&1 &
swaync-client --reload-css
echo "Wallpaper switch has been performed with no errors."
