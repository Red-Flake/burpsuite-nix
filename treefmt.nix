{ lib, pkgs, ... }: {
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
  on-unmatched = "fatal";
  tree-root-file = "treefmt.nix";
}
