{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption getExe;
  inherit (lib.types) attrsOf str;

  cfg = config.programs.java.userPrefs;

  # Convert attribute set to Java Prefs XML entries
  entriesToXml =
    entries:
    lib.concatStringsSep "\n  " (
      lib.mapAttrsToList (
        key: value: "<entry key=\"${lib.escapeXML key}\" value=\"${lib.escapeXML value}\"/>"
      ) entries
    );

  # Generate the complete XML document
  prefsToXml =
    entries:
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE map SYSTEM \"http://java.sun.com/dtd/preferences.dtd\">\n<map MAP_XML_VERSION=\"1.0\">\n  ${entriesToXml entries}\n</map>";

  # Helper to run gen.py and get encoded path
  # TODO: Only run this if necessary(forbidden character in the path)
  encodePathForJavaPrefs =
    p:
    lib.removeSuffix "\n" (
      builtins.readFile (
        pkgs.runCommand "encoded-path-${lib.strings.sanitizeDerivationName p}" { } ''
          ${getExe pkgs.jdk} ${./gen.java} --directory ${lib.escapeShellArg p} > $out
        ''
      )
    );

  # Generate shell commands for each path
  # TODO: Switch from home.activationScript to systemt.user.tmpfiles
  generateShellCommands = builtins.concatStringsSep "\n" (
    map (
      p:
      let
        encodedPath = encodePathForJavaPrefs p;
      in
      ''
        prefsDir="$HOME/.java/.userPrefs/$(printf %s ${lib.escapeShellArg encodedPath})"
        mkdir -p "$prefsDir"

        prefsFile="$prefsDir/prefs.xml"

        # Only write if file doesn't exist, use heredoc to safely handle all characters
        if [[ ! -f "$prefsFile" ]]; then
          cat > "$prefsFile" <<'EOF'
        ${prefsToXml (cfg.${p})}
        EOF
          chmod 644 "$prefsFile"
        fi
      ''
    ) (lib.attrNames cfg)
  );
in
{
  options = {
    programs.java.userPrefs = mkOption {
      type = attrsOf (attrsOf str);
      default = { };
      description = "Java user preferences as nested attribute sets. Each top-level key is a preference path, with nested key-value pairs for individual preferences.";
      # TODO: Change the data model to a nested tree
      example = {
        "burp" = {
          "global.suite.deviceId" = "vyogc3mm6uedd3ntpi58";
        };
        "burp/extensions/_HTTP Request Smuggler" = {
          "global.suite.deviceId" = "vyogc3mm6uedd3ntpi58";
        };
      };
    };
  };

  config = mkIf (cfg != { }) {
    home.activation.writeJavaUserPrefs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${generateShellCommands}
    '';
  };
}
