let
  # Raw, clean nixpkgs without overlays
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz") { };
in
pkgs.fetchzip {
  url = "https://portswigger.net/bappstore/bapps/download/0ab7a94d8e11449daaf0fb387431225b/8#js-miner.zip";
  sha256 = "";
  stripRoot=false;
}
