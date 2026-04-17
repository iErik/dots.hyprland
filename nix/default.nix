self: wallpapers: { pkgs, lib, config, ... }: let

  inherit (lib) mkOption mkIf types;
  inherit (lib.hm.dag) entryAfter;
  inherit (config.home) username homeDirectory;

  cfg = config.dots.hyprland;
  dotsDir = "${homeDirectory}/${cfg.directory}";
  xdgConfDir = "${homeDirectory}/.config/hypr";
  repoUrl = "git@github.com:iErik/dots.hyprland.git";

  wallpapersPackage = wallpapers.packages.${pkgs.system}.wallpapers;
  awwwPackage = wallpapers.inputs.awww.packages.${pkgs.system}.awww;

  # Env vars injected as a preamble into both wallpaper scripts.
  # transition.step is nullable: empty string means "let awww decide".
  # transition.invertY uses a non-empty string as truthy.
  transitionEnv = with cfg.wallpapers; ''
    WALLPAPERS_DIR="${wallpapersPackage}"
    TRANSITION_TYPE="${transition.type}"
    TRANSITION_STEP="${if transition.step != null then toString transition.step else ""}"
    TRANSITION_DURATION="${toString transition.duration}"
    TRANSITION_FPS="${toString transition.fps}"
    TRANSITION_ANGLE="${toString transition.angle}"
    TRANSITION_POS="${transition.pos}"
    TRANSITION_BEZIER="${transition.bezier}"
    TRANSITION_WAVE="${transition.wave}"
    TRANSITION_INVERT_Y="${if transition.invertY then "1" else ""}"
    RESIZE="${resize}"
    FILL_COLOR="${fillColor}"
    FILTER="${filter}"
  '';

  wallpaperScript = pkgs.writeShellApplication {
    name = "wallpaper-switch";
    runtimeInputs = [ pkgs.jq pkgs.hyprland awwwPackage ];
    text = transitionEnv + builtins.readFile ./wallpaper-switch.sh;
  };

  wallpaperInitScript = pkgs.writeShellApplication {
    name = "wallpaper-init";
    runtimeInputs = [ pkgs.jq awwwPackage ];
    text = transitionEnv + builtins.readFile ./wallpaper-init.sh;
  };

in {
  imports = [ wallpapers.homeManagerModules.default ];

  options.dots.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Hyprland Dotfiles module";
    };

    cloneConfig = mkOption {
      type = types.bool;
      default = false;
      description =
        "Clone the dotfiles repository to the user's " +
        "directory and symlink it to ~/.config/hypr " +
        "instead of deploying the .conf files directly " +
        "from the flake source.";
    };

    directory = mkOption {
      type = types.str;
      default = "Dots/Hyprland.dots";
      description =
        "The path of the directory in which to " +
        "store the dotfiles (relative to the " +
        "user's home directory).";
    };

    branch = mkOption {
      type = types.str;
      default = "master";
      description =
        "The branch to use as source for the dotfiles";
    };

    setup = mkOption {
      type = types.nullOr (types.enum [
        "zombie" "eminence" "lina" "mima"
      ]);
      default = null;
      description = ''
        Include a machine-specific setup file from ./setups.
        Deployed to ~/.config/hypr/setup.conf so it can be sourced
        from hyprland.conf with `source = ~/.config/hypr/setup.conf`.
        Only applies when cloneConfig = false.
      '';
    };

    wallpapers = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Wallpapers module";
      };

      resize = mkOption {
        type = types.enum [ "no" "crop" "fit" "stretch" ];
        default = "crop";
        description = ''
          How to resize wallpapers to fit the screen.
          crop: fill screen, cropping parts that don't fit (default).
          fit: fit inside screen, preserving aspect ratio.
          stretch: fit inside screen, ignoring aspect ratio.
          no: no resize; image is centered and padded with fillColor.
        '';
      };

      fillColor = mkOption {
        type = types.str;
        default = "000000ff";
        description = ''
          Color used for padding when the image does not fill the screen.
          Format: RRGGBBAA hex string (e.g. "000000ff" for opaque black).
        '';
      };

      filter = mkOption {
        type = types.enum [
          "Nearest" "Bilinear" "CatmullRom" "Mitchell" "Lanczos3"
        ];
        default = "Lanczos3";
        description = ''
          Scaling filter used when resizing images.
          Nearest is recommended for pixel art only; Lanczos3 is the
          best quality for photographs and general use.
        '';
      };

      transition = {
        type = mkOption {
          type = types.enum [
            "none" "simple" "fade"
            "left" "right" "top" "bottom"
            "wipe" "wave" "grow" "center" "any" "outer" "random"
          ];
          default = "simple";
          description = ''
            Transition effect used when switching wallpapers.
            none: instant switch (alias for simple with step=255).
            simple: cross-fade controlled by transition.step.
            fade: cross-fade controlled by transition.bezier.
            left/right/top/bottom: slide from that edge.
            wipe: angled wipe, angle set by transition.angle.
            wave: wavy wipe, shaped by transition.wave.
            grow: expanding circle, centered at transition.pos.
            center: alias for grow at screen center.
            any: alias for grow at a random screen position.
            outer: shrinking circle (inverse of grow).
            random: picks a random effect each time.
          '';
        };

        step = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = ''
            How much the pixel values change per frame toward the new image.
            Higher values make the transition faster but more abrupt; 255
            switches instantly. Defaults to 2 for simple/fade and 90 for
            all other types (awww built-in default). Set to null to use
            awww's per-type default.
          '';
        };

        duration = mkOption {
          type = types.number;
          default = 3;
          description = ''
            How long the transition takes to complete, in seconds.
            Has no effect on the simple transition.
          '';
        };

        fps = mkOption {
          type = types.int;
          default = 30;
          description = ''
            Frame rate of the transition animation. There is no benefit
            in setting this higher than your monitor's refresh rate.
          '';
        };

        angle = mkOption {
          type = types.number;
          default = 45;
          description = ''
            Angle of the transition in degrees, used by wipe and wave.
            0 = right-to-left, 90 = top-to-bottom, 270 = bottom-to-top.
          '';
        };

        pos = mkOption {
          type = types.str;
          default = "center";
          description = ''
            Center position for the grow and outer transitions.
            Accepts pixel values (e.g. "200,400"), percentage values
            (e.g. "0.5,0.5"), or named aliases:
            center | top | left | right | bottom |
            top-left | top-right | bottom-left | bottom-right
          '';
        };

        bezier = mkOption {
          type = types.str;
          default = ".54,0,.34,.99";
          description = ''
            Cubic bezier curve controlling the fade transition's easing.
            Format: "x1,y1,x2,y2". Use https://cubic-bezier.com to
            preview curves. Example: "0.0,0.0,1.0,1.0" for linear.
          '';
        };

        wave = mkOption {
          type = types.str;
          default = "20,20";
          description = ''
            Width and height of each wave for the wave transition.
            Format: "width,height" (e.g. "20,20").
          '';
        };

        invertY = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Invert the Y axis of transition.pos.
            Useful when the coordinate origin differs from expectation.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    dots.wallpapers = mkIf cfg.wallpapers.enable {
      enable = true;
      awww.enable = true;
      location = "~/Dots/Wallpapers";
    };

    home.packages = (with pkgs; [
      swaynotificationcenter
      hyprpaper
      hyprpolkitagent
      hyprsome
      rofi
      kitty
      grimblast
      pamixer
      wl-color-picker
      jq
    ]) ++ lib.optionals cfg.wallpapers.enable [
      wallpaperScript
      wallpaperInitScript
    ];

    home.file = lib.mkMerge [
      (mkIf (!cfg.cloneConfig) {
        ".config/hypr/hyprland.conf".source  = ../hyprland.conf;
        ".config/hypr/env.conf".source       = ../env.conf;
        ".config/hypr/monitors.conf".source  = ../monitors.conf;
        ".config/hypr/rules.conf".source     = ../rules.conf;
        ".config/hypr/bindings.conf".source  = ../bindings.conf;
        ".config/hypr/hyprpaper.conf".source = ../hyprpaper.conf;
      })
      (mkIf (!cfg.cloneConfig && cfg.setup != null) {
        ".config/hypr/setup.conf".source = ../setups + "/${cfg.setup}.conf";
      })
      (mkIf cfg.wallpapers.enable {
        "${cfg.directory}/wallpaper-keys.conf".text = ''
          bind = SUPER,       period, exec, ${wallpaperScript}/bin/wallpaper-switch next image
          bind = SUPER,       comma,  exec, ${wallpaperScript}/bin/wallpaper-switch prev image
          bind = SUPER ALT_L, period, exec, ${wallpaperScript}/bin/wallpaper-switch next folder
          bind = SUPER ALT_L, comma,  exec, ${wallpaperScript}/bin/wallpaper-switch prev folder
        '';
      })
    ];

    systemd.user.services.wallpaper-init = mkIf cfg.wallpapers.enable {
      Unit = {
        Description = "Set a random wallpaper on session start";
        After = [ "awww.service" "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${wallpaperInitScript}/bin/wallpaper-init";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    home.activation.hyprlandSetup = mkIf cfg.cloneConfig
      (entryAfter ["writeBoundary"] ''
        export PATH=${pkgs.openssh}/bin:$PATH
        export PATH=${pkgs.git}/bin:$PATH

        eval $(ssh-agent -s)
        ssh-add

        if [ -d "${dotsDir}/.git" ];
        then
          cd ${dotsDir} && git pull origin ${cfg.branch}
        else
          rm -rf ${dotsDir}
          rm -rf ${xdgConfDir}

          git clone -b ${cfg.branch} --single-branch ${repoUrl} ${dotsDir}

          chown -R ${username}:users ${dotsDir}
          find ${dotsDir} -type d -exec chmod 744 {} \;
          find  ${dotsDir} -type f -exec chmod 644 {} \;

          ln -s ${dotsDir} ${xdgConfDir}
        fi

        ssh-agent -k
      '');
  };
}
