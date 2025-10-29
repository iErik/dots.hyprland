{
  description = "";

  inputs = {};

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    #packages.${system}.default = pkgs.callPackage ./nix/pkgs/emacs.nix { };

    homeManagerModules = {
      default = self.homeManagerModules.dots;
      dots = import ./nix/modules/hm.nix self;
    };
  };
}
