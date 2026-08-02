#!/bin/bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

# Variables
WALL_DIR="$HOME/Wallpapers"
TMP="/tmp/wall_thumb.png"

echo "Retrieving choice using Yazi..."

# Retrieve the wallpaper choice by running Yazi. 
yazi --chooser-file /tmp/choice ~/Wallpapers

FILE=$(</tmp/choice)
echo "Chosen wallpaper: $FILE"

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

    # Copy the wallpaper to '~/.cache/current_wallpaper.png'
    cp "$FILE" "$HOME/.cache/current_wallpaper.png"
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
    
    # Copy the first frame of the wallpaper to '~/.cache/current_wallpaper.png'
    ffmpeg -y -i "$FILE" -frames:v 1 "$HOME/.cache/current_wallpaper.png"

  ;;
esac 

# Reload colors for various applications.
nvim --headless "+LushwalCompile" +q
pkill waybar; waybar >/dev/null 2>&1 &
swaync-client --reload-css
echo "Wallpaper switch has been performed with no errors."
