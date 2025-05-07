{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      system = "macos";  # linux/macos
      desktopEnvironment = "sway"; # Change this to i3, sway, hyprland, etc.
      pkgs = import nixpkgs { inherit system; };
    in {
      nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/base.nix
          ./modules/${system}.nix
          #./modules/desktop/${desktopEnvironment}.nix
        ];
      };
    };
}
