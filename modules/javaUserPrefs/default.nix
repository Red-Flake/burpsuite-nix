{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.java.userPrefs;

  javaLib = import ./lib.nix {
    inherit lib pkgs;
  };

  assertValidTree =
    tree:
    lib.all (value: builtins.isString value || (builtins.isAttrs value && assertValidTree value)) (
      lib.attrValues tree
    );

  generateTmpfilesRules =
    let
      prefs = javaLib.flattenPrefs "" cfg;

      directoryRules = lib.unique (
        [
          "d %h/.java 0755 - - -"
          "d %h/.java/.userPrefs 0755 - - -"
        ]
        ++ lib.flatten (
          map (
            prefsPath:
            (map (parent: "d %h/.java/.userPrefs/${parent} 0755 - - -") (javaLib.parentPaths prefsPath))
            ++ [
              "d %h/.java/.userPrefs/${prefsPath} 0755 - - -"
            ]
          ) (lib.attrNames prefs)
        )
      );

      fileRules = lib.concatLists (
        lib.mapAttrsToList (
          prefsPath: entries:
          let
            xml = pkgs.writeText "java-prefs-${lib.strings.sanitizeDerivationName prefsPath}.xml" (
              javaLib.prefsToXml entries
            );

            prefsFile = "%h/.java/.userPrefs/${prefsPath}/prefs.xml";
          in
          [
            "C ${lib.escapeShellArg prefsFile} 0644 - - - ${xml}"
          ]
        ) prefs
      );
    in
    directoryRules ++ fileRules;

in
{
  options.programs.java.userPrefs = mkOption {
    type = lib.types.attrsOf lib.types.anything;

    default = { };

    description = ''
      Java user preferences represented as a nested attribute tree.

      Attribute sets represent Java Preferences nodes. Attribute sets
      containing string values represent preference entries stored in that
      node. Nested attribute sets represent child preference nodes.

      Node names are encoded automatically when required by the Java
      Preferences file format.
    '';

    example = {
      burp = {
        "global.suite.deviceId" = "vyogc3mm6uedd3ntpi58";

        extensions = {
          "_JWT Editor" = {
            "global.suite.deviceId" = "vyogc3mm6uedd3ntpi58";
          };
        };
      };
    };
  };

  config = mkIf (cfg != { }) {
    assertions = [
      {
        assertion = assertValidTree cfg;
        message = ''
          programs.java.userPrefs must only contain strings and nested
          attribute sets.
        '';
      }
    ];

    systemd.user.tmpfiles.rules = generateTmpfilesRules;
  };
}
