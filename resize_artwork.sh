#!/bin/bash
set -euo pipefail

TARGET_W=3840
TARGET_H=2160

if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Error: '$dir' is not a directory"
    exit 1
fi

# Collect images that need resizing
to_resize=()
skipped=0

for file in "$dir"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
    [ -f "$file" ] || continue
    dims=$(magick identify -format "%wx%h" "$file" 2>/dev/null) || continue
    w=${dims%x*}
    h=${dims#*x}
    if [ "$w" -ne "$TARGET_W" ] || [ "$h" -ne "$TARGET_H" ]; then
        to_resize+=("$file")
        echo "  $(basename "$file"): ${w}x${h}"
    else
        skipped=$((skipped + 1))
    fi
done

if [ ${#to_resize[@]} -eq 0 ]; then
    echo "All images are already ${TARGET_W}x${TARGET_H}. Nothing to do."
    exit 0
fi

echo ""
echo "${#to_resize[@]} image(s) will be resized to ${TARGET_W}x${TARGET_H} (fill + center crop) in place."
[ $skipped -gt 0 ] && echo "$skipped image(s) already at target size, skipping."
echo ""
read -p "Proceed? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
for file in "${to_resize[@]}"; do
    name=$(basename "$file")
    echo -n "Resizing $name..."
    magick "$file" -resize "${TARGET_W}x${TARGET_H}^" -gravity center -extent "${TARGET_W}x${TARGET_H}" "$file"
    echo " done"
done

echo ""
echo "Resized ${#to_resize[@]} image(s)."
