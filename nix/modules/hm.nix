self: { pkgs, lib, config, .. }: let
  inherit (lib) mkOption mkEnableOption mkIf types;
  inherit (config.home) username homeDirectory;

  cfg = config.dots.hyprland;
in {
  options.dots.hyprland = {};

  config = mkIf cfg.enable {
    home.packages = {};

    wayland.windowManager.hyprland = {

    }
  };
}
