{
  description = "Erik's personal Hyprland dots flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    homeManagerModules = {
      default = self.homeManagerModules.dots;
      dots = import ./nix/modules/hm.nix self;
    };
  };
}
