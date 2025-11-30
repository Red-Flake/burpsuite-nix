{
  description = "BurpSuite extensions package set (x86_64-linux only)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      eachSystem =
        f:
        lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          in
          f pkgs
        );

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      packages = eachSystem (
        pkgs:
        let
          bappPackages = import ./pkgs {
            inherit lib pkgs;
            inherit (pkgs) fetchzip;
          };
          docs = pkgs.callPackage ./docs.nix { inherit pkgs self; };
        in
        bappPackages // { inherit docs; }
      );

      homeManagerModules.default = {
        _module.args = {
          burpPackages = self.packages;
        };
        imports = [ ./modules/burp.nix ];
      };

      formatter = eachSystem (
        pkgs:
        pkgs.treefmt.withConfig {
          settings = lib.mkMerge [
            ./treefmt.nix
            { _module.args = { inherit pkgs; }; }
          ];
        }
      );

      checks = eachSystem (pkgs: {

        fmt = pkgs.runCommandLocal "fmt-check" { } ''
          cp -r --no-preserve=mode ${self} repo
          ${lib.getExe self.formatter.${pkgs.stdenv.hostPlatform.system}} -C repo --ci
          touch $out
        '';

        docs = pkgs.runCommandLocal "docs-check" { } ''
          diff -U3 --color=auto ${./nixos-options.md} ${self.packages.${pkgs.stdenv.hostPlatform.system}.docs}
          touch $out
        '';
      });
    };
  nixConfig = {
    abort-on-warn = true;
    commit-lock-file-summary = "chore: update flake.lock";
  };
}
