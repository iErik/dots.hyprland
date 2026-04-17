# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Hyprland (Wayland compositor) dotfiles repository. Files are deployed by symlinking or copying to `~/.config/hypr/`.

## Applying Changes

Changes take effect after reloading Hyprland:

```sh
hyprctl reload
```

For monitor/workspace changes, a full Hyprland restart may be needed. Individual components can also be restarted (e.g., `pkill hyprpaper && hyprpaper &`).

## Config Architecture

`hyprland.conf` is the entry point; it sources the other files in order:

- `env.conf` — Wayland environment variables (Qt, GTK, XDG, cursor size)
- `monitors.conf` — Physical display setup and workspace-to-monitor assignments
- `rules.conf` — Per-application window rules (opacity, float/tile, positioning)
- `bindings.conf` — All keybindings

`hyprpaper.conf` is standalone (used by the `hyprpaper` process, not sourced by hyprland.conf).

## Multi-Monitor Workspace Numbering

Each monitor owns a dedicated range of 9 workspaces. `hyprsome` maps `Super+1..9` to the correct absolute workspace ID for whichever monitor is focused:

| Monitor | Connector | Workspaces |
|---------|-----------|------------|
| 34" Ultrawide | DP-2 | 1–9 |
| 29" Vertical Ultrawide | DP-3 | 11–19 |
| 24" Monitor | HDMI-A-1 | 21–29 |
| 60" 4K TV | HDMI-A-2 | 31–39 |

When editing workspace rules or adding new workspaces, preserve this `X` / `X1` / `X2` / `X3` decade scheme.

## Keyboard Layout Notes

The built-in keyboard uses `altgr-intl` variant with `caps:escape` (Caps Lock acts as Escape) and `compose:ralt` (right Alt is Compose). The external GK64s gaming keyboard overrides `compose:menu` (Menu key is Compose).

## Open TODOs

The following features are not yet implemented (marked at top of `hyprland.conf`):

- Screenshotting / screen recording
- Notifications (swaync is running but not configured)
- Animations refinement
- Workspace behavior tweaks
- Logout / suspend / poweroff / restart actions

Several plugins (`hyprexpo`, `scroller`) and bindings are commented out in `bindings.conf` and `hyprland.conf` and can be re-enabled.

## flake.nix

The `flake.nix` is a placeholder — it currently only exposes the `hello` package. The `nix/` directory is empty. Nix-based deployment is not yet implemented.
