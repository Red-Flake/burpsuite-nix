{ lib, pkgs, ... }: {
  tree-root-file = "treefmt.nix";
  on-unmatched = "fatal";
  excludes = [
    "*.lock"
    "*.md"
    "LICENSE"
    ".gitignore"
    "data/*"
    ".envrc"
    "*.yaml"
    "*.yml"
    "*.java"
  ];

  formatter.nixfmt = {
    command = lib.getExe pkgs.nixfmt;
    includes = [ "*.nix" ];
    options = [ "--strict" ];
  };
}
