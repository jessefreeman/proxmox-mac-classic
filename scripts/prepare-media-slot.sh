#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: prepare-media-slot.sh <mountpoint> <image1> [image2...]

Formats or reuses a mounted media-slot filesystem and copies classic Mac
images into deterministic order:
  001-*
  010-*
  020-*
EOF
}

[[ $# -ge 2 ]] || { usage >&2; exit 1; }

mountpoint_path="$1"
shift

[[ -d "$mountpoint_path" ]] || { echo "Missing mountpoint: $mountpoint_path" >&2; exit 1; }

rm -f "$mountpoint_path"/*.{img,dsk,hfv,hda,toast,iso} 2>/dev/null || true

index=1
for source_path in "$@"; do
  [[ -f "$source_path" ]] || { echo "Missing media file: $source_path" >&2; exit 1; }
  printf -v prefix '%03d' "$index"
  target_name="${prefix}-$(basename "$source_path")"
  cp -f "$source_path" "$mountpoint_path/$target_name"
  index=$((index + 9))
done

sync
echo "Prepared media slot at $mountpoint_path"
