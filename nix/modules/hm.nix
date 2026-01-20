self: { pkgs, lib, config, .. }: let
  inherit (lib) mkOption mkEnableOption mkIf types;
  inherit (config.home) username homeDirectory;

  cfg = config.dots.hyprland;
  dotsDir = "${homeDirectory}/${cfg.directory}";
  xdgConfDir = "${homeDirectory}/.config/hypr";
  repoUrl = "git@github.com:iErik/dots.hyprland.git";
in {
  options.dots.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NeoVim Dotfiles module";
    };

    cloneConfig = mkOption {
      type = types.bool;
      default = true;
      description =
        "Whether or not to clone the Dotfiles" +
        "repository to the user's directory";
    };

    directory = mkOption {
      type = types.str;
      default = "Dots/NeoVim.dot";
      description =
        "The path of the directory in which to " +
        "store the dotfiles (relative to the " +
        "user's home directory).";
    };

    branchName = mkOption {
      type = types.str;
      default = "flake";
      description = "The name of the branch to clone.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      xdg-utils
      qt6.qtwayland
      libsForQt5.qt5.qtwayland
      wpaperd
      hyprpaper
      gammastep
      slurp
      rofi
      wl-color-picker
      wl-clipboard
      wev
      phinger-cursors
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
    }

    home.activation.hyprSetup = mkIf cfg.cloneConfig
      (entryAfter ["writeBoundary"] ''
        export PATH=${pkgs.openssh}/bin:$PATH
        export PATH=${pkgs.git}/bin:$PATH

        eval $(ssh-agent -s)
        ssh-add

        if [ -d "${dotsDir}/.git" ];
        then
          cd ${dotsDir} && git pull origin master
        else
          rm -rf ${dotsDir}
          rm -rf ${xdgConfDir}

          git clone ${repoUrl} ${dotsDir}

          chown -R ${username}:users ${dotsDir}
          find ${dotsDir} -type d -exec chmod 744 {} \;
          find  ${dotsDir} -type f -exec chmod 644 {} \;

          ln -s ${dotsDir} ${xdgConfDir}
        fi

        ssh-agent -k
      '');
  };
}
