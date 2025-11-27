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

    drv = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
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

        # Extract extension
        ext=$(basename "$entrypoint" | sed 's/.*\.//')

        # Conditional symlink based on extension
        if [ "$ext" = "py" ]; then
          ln -s "$out/lib/${pname}/$entrypoint" "$out/lib/${pname}/${pname}.py"
        elif [ "$ext" = "jar" ]; then
          ln -s "$out/lib/${pname}/$entrypoint" "$out/lib/${pname}/${pname}.jar"
        elif [ "$ext" = "rb" ]; then
          ln -s "$out/lib/${pname}/$entrypoint" "$out/lib/${pname}/${pname}.rb"
        else
          echo "Unknown EntryPoint extension: $ext" >&2
        fi

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
        };
      };
    });
  in
  acc // { ${pname} = drv; }
) { } universe
