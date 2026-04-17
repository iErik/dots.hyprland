# All-caps variables above this line are injected by Nix.

# Wait for awww to be ready (it may take a moment to connect to the compositor)
for _ in {1..10}; do
  awww query -j &>/dev/null && break
  sleep 0.5
done

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"

# Get all outputs that don't have a wallpaper set.
mapfile -t OUTPUTS_WITHOUT_WP < <(awww query -j \
  | jq -r '.[""] | .[] | select(.displaying | has("image") | not) | .name')

if [[ ${#OUTPUTS_WITHOUT_WP[@]} -eq 0 ]]; then
  exit 0
fi

# Shared awww arg list (built from injected transition config).
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
[[ -n "$TRANSITION_STEP" ]]    && AWWW_ARGS+=(--transition-step "$TRANSITION_STEP")
[[ -n "$TRANSITION_INVERT_Y" ]] && AWWW_ARGS+=(--invert-y)

# First pass: restore the last chosen wallpaper per output where we have one.
NEEDS_RANDOM=()
for output in "${OUTPUTS_WITHOUT_WP[@]}"; do
  STATE_FILE="$STATE_DIR/${output}.path"
  if [[ -f "$STATE_FILE" ]]; then
    SAVED_PATH=$(<"$STATE_FILE")
    if [[ -n "$SAVED_PATH" && -f "$SAVED_PATH" ]]; then
      awww img -o "$output" "${AWWW_ARGS[@]}" "$SAVED_PATH"
      continue
    fi
  fi
  NEEDS_RANDOM+=("$output")
done

if [[ ${#NEEDS_RANDOM[@]} -eq 0 ]]; then
  exit 0
fi

# Second pass: pick a random wallpaper for outputs with no saved state.
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

mapfile -t -d '' LEAF_DIRS < <(get_leaf_dirs)
TOTAL_DIRS=${#LEAF_DIRS[@]}

if [[ $TOTAL_DIRS -eq 0 ]]; then
  echo "wallpaper-init: no wallpaper folders found in $WALLPAPERS_DIR" >&2
  exit 1
fi

# Pick one random leaf directory shared across all stateless outputs
RANDOM_DIR="${LEAF_DIRS[$(( RANDOM % TOTAL_DIRS ))]}"

mapfile -t -d '' IMAGES < <(find "$RANDOM_DIR" -maxdepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
     -o -iname "*.gif" -o -iname "*.webp" \) \
  -print0 | sort -z)
TOTAL_IMAGES=${#IMAGES[@]}

if [[ $TOTAL_IMAGES -eq 0 ]]; then
  echo "wallpaper-init: no images found in $RANDOM_DIR" >&2
  exit 1
fi

mkdir -p "$STATE_DIR"
for output in "${NEEDS_RANDOM[@]}"; do
  CHOSEN="${IMAGES[$(( RANDOM % TOTAL_IMAGES ))]}"
  awww img -o "$output" "${AWWW_ARGS[@]}" "$CHOSEN"
  printf '%s\n' "$CHOSEN" > "$STATE_DIR/${output}.path"
done
