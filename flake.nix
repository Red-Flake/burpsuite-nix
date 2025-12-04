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

      homeConfigurations.example = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        modules = [
          self.homeManagerModules.default
          {
            home = rec {
              stateVersion = "25.05";
              username = "alice";
              homeDirectory = "/home/${username}";
            };

            programs.burp = {
              enable = true;

              extensions = [
                # Loaded by default
                "403-bypasser"
                "json-web-tokens"
                "js-miner"
                "param-miner"

                # Installed but not loaded
                {
                  package = "http-request-smuggler";
                  loaded = false;
                }
              ];

              # Define which file will be installed, defaults to community
              edition = [
                "Community"
                "Pro"
              ];

              # Settings that are deep-merged into the default config
              settings = {
                display.user_interface = {
                  # Enable Darkmode
                  look_and_feel = "Dark";
                  # Change Scaling
                  font_size = "17";
                };
              };
            };
          }
        ];
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

      devShells = eachSystem (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              self.formatter.${system}

              (pkgs.writeShellScriptBin "mkdocs" ''
                cp ${self.packages.${system}.docs} nixos-options.md
              '')
            ];
          };
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
