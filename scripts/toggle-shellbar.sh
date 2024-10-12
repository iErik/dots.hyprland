#!/run/current-system/sw/bin/bash

activeMonitor=$(hyprctl activewindow -j | jq -r '.monitor')

ags -t shellbar-${activeMonitor}
