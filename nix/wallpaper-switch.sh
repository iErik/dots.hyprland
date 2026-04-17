# All-caps variables above this line are injected by Nix.

DIRECTION="${1:?Usage: wallpaper-switch <next|prev> <image|folder>}"
SCOPE="${2:?Usage: wallpaper-switch <next|prev> <image|folder>}"

FOCUSED_OUTPUT=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
if [[ -z "$FOCUSED_OUTPUT" || "$FOCUSED_OUTPUT" == "null" ]]; then
  echo "wallpaper-switch: could not determine focused output" >&2
  exit 1
fi

# awww query -j format: {"": [{name, ..., displaying: {image: "..."}}]}
# .displaying.image is absent when only a color is showing
CURRENT_PATH=$(awww query -j \
  | jq -r --arg out "$FOCUSED_OUTPUT" \
    '.[""] | .[] | select(.name == $out) | .displaying.image // empty')

# Print all leaf dirs (dirs that directly contain image files) under
# WALLPAPERS_DIR, null-delimited and sorted. Handles paths with spaces.
get_leaf_dirs() {
  while IFS= read -r -d '' dir; do
    if find "$dir" -maxdepth 1 -type f \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
         -o -iname "*.gif" -o -iname "*.webp" \) \
      -print -quit 2>/dev/null | grep -q .; then
      printf '%s\0' "$dir"
    fi
  done < <(find "$WALLPAPERS_DIR" -mindepth 1 -type d -print0 | sort -z)
}

if [[ "$SCOPE" == "image" ]]; then
  if [[ -z "$CURRENT_PATH" ]]; then
    # No wallpaper set yet — bootstrap to first image in first leaf dir
    read -r -d '' CURRENT_DIR < <(get_leaf_dirs) || true
  else
    CURRENT_DIR=$(dirname "$CURRENT_PATH")
  fi

  mapfile -t -d '' ITEMS < <(find "$CURRENT_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
       -o -iname "*.gif" -o -iname "*.webp" \) \
    -print0 | sort -z)

  CURRENT_ITEM="$CURRENT_PATH"

elif [[ "$SCOPE" == "folder" ]]; then
  mapfile -t -d '' ITEMS < <(get_leaf_dirs)

  CURRENT_ITEM=""
  if [[ -n "$CURRENT_PATH" ]]; then
    CURRENT_ITEM=$(dirname "$CURRENT_PATH")
  fi
else
  echo "wallpaper-switch: unknown scope '$SCOPE'" >&2
  exit 1
fi

TOTAL=${#ITEMS[@]}
if [[ $TOTAL -eq 0 ]]; then
  echo "wallpaper-switch: no items found in $WALLPAPERS_DIR" >&2
  exit 1
fi

# Find current index; default to 0 (wraps correctly on first use)
CURRENT_INDEX=0
for i in "${!ITEMS[@]}"; do
  if [[ "${ITEMS[$i]}" == "$CURRENT_ITEM" ]]; then
    CURRENT_INDEX=$i
    break
  fi
done

if [[ "$DIRECTION" == "next" ]]; then
  NEW_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL ))
else
  NEW_INDEX=$(( (CURRENT_INDEX - 1 + TOTAL) % TOTAL ))
fi

if [[ "$SCOPE" == "folder" ]]; then
  # Pick the first image in the target folder
  TARGET_PATH=$(find "${ITEMS[$NEW_INDEX]}" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
       -o -iname "*.gif" -o -iname "*.webp" \) \
    -print0 | sort -z | { read -r -d '' f; printf '%s' "$f"; })
else
  TARGET_PATH="${ITEMS[$NEW_INDEX]}"
fi

if [[ -z "$TARGET_PATH" ]]; then
  echo "wallpaper-switch: could not resolve target path" >&2
  exit 1
fi

# Build awww img argument list from injected transition config.
# TRANSITION_STEP is empty when null (let awww use its per-type default).
# TRANSITION_INVERT_Y is non-empty when true.
AWWW_ARGS=(
  --transition-type    "$TRANSITION_TYPE"
  --transition-duration "$TRANSITION_DURATION"
  --transition-fps     "$TRANSITION_FPS"
  --transition-angle   "$TRANSITION_ANGLE"
  --transition-pos     "$TRANSITION_POS"
  --transition-bezier  "$TRANSITION_BEZIER"
  --transition-wave    "$TRANSITION_WAVE"
  --resize             "$RESIZE"
  --fill-color         "$FILL_COLOR"
  --filter             "$FILTER"
)
[[ -n "$TRANSITION_STEP" ]]   && AWWW_ARGS+=(--transition-step "$TRANSITION_STEP")
[[ -n "$TRANSITION_INVERT_Y" ]] && AWWW_ARGS+=(--invert-y)

awww img -o "$FOCUSED_OUTPUT" "${AWWW_ARGS[@]}" "$TARGET_PATH"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
mkdir -p "$STATE_DIR"
printf '%s\n' "$TARGET_PATH" > "$STATE_DIR/${FOCUSED_OUTPUT}.path"
