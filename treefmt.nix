{ lib, pkgs, ... }:

{
  tree-root-file = "treefmt.nix";
  on-unmatched = "fatal";
  excludes = [
    "*.lock"
    "*.md"
    "LICENSE"
    ".gitignore"
    "data/*"
    ".envrc"
  ];

  formatter.nixfmt = {
    command = lib.getExe pkgs.nixfmt-rfc-style;
    includes = [ "*.nix" ];
    options = [ "--strict" ];
  };
}
