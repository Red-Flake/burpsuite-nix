{
  lib,
  pkgs,
  fetchzip,
}:

let
  extensions = lib.importTOML ../data/burp-extensions.toml;
in
lib.mapAttrs (
  pname: versionSet:
  let
    latest = lib.last (lib.attrNames versionSet);
    pkg = versionSet.${latest};
  in
  pkgs.stdenvNoCC.mkDerivation {
    inherit pname;
    version = latest;

    src = fetchzip {
      inherit (pkg) hash;
      # Workaround for: https://github.com/NixOS/nixpkgs/issues/60157, append the URL Fragment to recognize it as a ZIP
      url = "https://portswigger.net/bappstore/bapps/download/${pkg.uuid}/${pkg.serialversion}#.zip";
      stripRoot = false;
    };

    name = "burpsuite-extension-${pname}-${latest}";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/${pname}
      cp -r $src/* $out/lib/${pname}/

      runHook postInstall
    '';

    meta = {
      description = "${pkg.name} Extension for BurpSuite";
      maintainers = with lib.maintainers; [ letgamer ];
      license = lib.licenses.unfree;
      homepage = "https://github.com/portswigger/${pname}";
    };

    passthru.burp = {
      inherit (pkg)
        extensiontype
        name
        serialversion
        uuid
        ;
    };
  }
) extensions
