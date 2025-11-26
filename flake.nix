{
  description = "BurpSuite extensions package set (x86_64-linux only)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
      lib = pkgs.lib;

      bappPackages = import ./bapp-packages.nix {
        inherit lib pkgs;
        inherit (pkgs) fetchzip;
      };

    in
    {
      packages.${system} = bappPackages;
    };

  nixConfig = {
    abort-on-warn = true;
    commit-lock-file-summary = "chore: update flake.lock";
    allowUnfree = true;
  };
}
