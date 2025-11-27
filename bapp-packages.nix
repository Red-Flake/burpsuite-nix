{
  lib,
  pkgs,
  fetchzip,
}:

let
  universe = lib.importTOML ./burp-extensions.toml;
in
lib.foldlAttrs (
  acc: pname: versionSet:
  let
    latest = lib.last (lib.attrNames versionSet);
    pkg = versionSet.${latest};

    drv = pkgs.stdenvNoCC.mkDerivation {
      pname = pname;
      version = latest;

      src = fetchzip {
        inherit (pkg) hash;
        # Workaround for: https://github.com/NixOS/nixpkgs/issues/60157
        url = "https://portswigger.net/bappstore/bapps/download/${pkg.uuid}/${pkg.serialversion}#.zip";
        stripRoot = false;
      };

      name = "burpsuite-extension-${pname}-${latest}";

      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/${pname}
        cp -r $src/* $out/lib/${pname}/

        # Read EntryPoint from BappManifest.bmf
        entrypoint=$(grep '^EntryPoint:' "$out/lib/${pname}/BappManifest.bmf" | sed 's/EntryPoint:[[:space:]]*//')

        if [ -z "$entrypoint" ]; then
          echo "Missing EntryPoint in ${pname}" >&2
          exit 1
        fi

        # Extract extension
        ext=$(basename "$entrypoint" | sed 's/.*\.//')

        # Symlink the Entrypoint script into the root of the project to ensure having the same location
        # This should work for most packages but specific python projects could fail, consider extracting the Entrypoint in the home manager module
        ln -s "$out/lib/${pname}/$entrypoint" "$out/lib/${pname}/${pname}.$ext"

        runHook postInstall
      '';

      meta = {
        description = "${pkg.name} Extension for BurpSuite";
        maintainers = with lib.maintainers; [ letgamer ];
        license = lib.licenses.unfree;
        homepage = "https://github.com/portswigger/${pname}";
      };

      passthru = {
        burp = {
          uuid = pkg.uuid;
          serialversion = pkg.serialversion;
          name = pkg.name;
          extensiontype = pkg.extensiontype;
          manifest = "${drv}/lib/${pname}/BappManifest.bmf";
        };
      };
    };
  in
  acc // { ${pname} = drv; }
) { } universe
