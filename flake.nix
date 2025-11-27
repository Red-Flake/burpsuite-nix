{
  description = "BurpSuite extensions package set (x86_64-linux only)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      inherit (nixpkgs) lib;

      bappPackages = import ./bapp-packages.nix {
        inherit lib pkgs;
        inherit (pkgs) fetchzip;
      };

    in
    {
      packages.${system} = bappPackages;

      # This exposes your module for others to import:
      homeManagerModules.default = ./modules/burp.nix;
    };

  nixConfig = {
    abort-on-warn = true;
    commit-lock-file-summary = "chore: update flake.lock";
  };
}
