#!/bin/bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

# Variables
WALL_DIR="$HOME/Wallpapers"
TMP="/tmp/wall_thumb.png"

# Thumbnail cache
CACHE_DIR="$HOME/.cache/wallpaper-picker"
mkdir -p "$CACHE_DIR"

echo "Defining generate_menu() function..."

generate_menu() {
    find "$WALL_DIR" -type f \
        \( \
        -iname "*.png" \
        -o -iname "*.jpg" \
        -o -iname "*.jpeg" \
        -o -iname "*.mp4" \
        \) |
    shuf |
    while read -r file; do

        rel="${file#$WALL_DIR/}"
        thumb="$CACHE_DIR/${rel}.thumb.png"

        [[ -f "$thumb" ]] || continue

        printf "img:%s\0%s\n" \
            "$thumb" \
            "$rel"
    done
}

echo "Generating Wofi menu..."

FILE=$(
    generate_menu | 
    wofi \
        --conf ~/.config/wofi/wallpaper.conf \
        --cache-file /dev/null
)

[[ -z "$FILE" ]] && exit 0

echo "Cleaning selected file..."

# Remove the 'img:' prefix
FILE="${FILE#img:}"
# Replace cache directory with wallpaper directory
FILE="${FILE/$CACHE_DIR/$WALL_DIR}"
# Remove thumbnail suffix
FILE="${FILE%.thumb.png}"

echo "Final path of selected file: $FILE"

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
    
    # Copy the wallpaper to '~/.cache/current-wallpaper.png'
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
