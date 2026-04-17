{
  description = "Erik's personal Hyprland dots flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    wallpapers.url = "git+ssh://git@github.com/iErik/Wallpapers";
    wallpapers.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, wallpapers }: {
    homeManagerModules = {
      default = self.homeManagerModules.hyprland;
      hyprland = import ./nix/default.nix self wallpapers;
    };
  };
}
