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
  prefsToXml = entries: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">
    <map MAP_XML_VERSION="1.0">
      ${entriesToXml entries}
    </map>
  '';

  needsEncoding =
    path: builtins.match "^[ -~]*$" path == null || builtins.match ".*[./_].*" path != null;

  # Helper to run gen.java and get the encoded path
  encodePathForJavaPrefs =
    path:
    if needsEncoding path then
      lib.removeSuffix "\n" (
        builtins.readFile (
          pkgs.runCommand "encoded-path-${lib.strings.sanitizeDerivationName path}" { } ''
            ${getExe pkgs.jdk} ${./gen.java} --directory ${lib.escapeShellArg path} > $out
          ''
        )
      )
    else
      path;

  generateTmpfilesRules = [
    "d %h/.java 0755 - - -"
    "d %h/.java/.userPrefs 0755 - - -"
  ]
  ++ lib.concatLists (
    lib.mapAttrsToList (
      path: entries:
      let
        encodedPath = encodePathForJavaPrefs path;

        xml = pkgs.writeText "java-prefs-${lib.strings.sanitizeDerivationName encodedPath}.xml" (
          prefsToXml entries
        );

        prefsDir = "%h/.java/.userPrefs/${encodedPath}";
      in
      [
        "d ${lib.escapeShellArg prefsDir} 0755 - - -"
        "C ${lib.escapeShellArg prefsDir}/prefs.xml 0644 - - - ${xml}"
      ]
    ) cfg
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
        burp = {
          "global.suite.deviceId" = "vyogc3mm6uedd3ntpi58";
        };
        "burp/extensions/_HTTP Request Smuggler" = {
          "global.suite.deviceId" = "vyogc3mm6uedd3ntpi58";
        };
      };
    };
  };

  config = mkIf (cfg != { }) {
    systemd.user.tmpfiles.rules = generateTmpfilesRules;
  };
}
