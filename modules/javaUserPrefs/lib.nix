{ lib, pkgs }:

let
  inherit (lib)
    getExe
    match
    readFile
    isString
    isAttrs
    foldl'
    ;
in
rec {
  concatPath = parent: child: if parent == "" then child else "${parent}/${child}";

  needsEncoding = name: match "^[ -~]*$" name == null || match ".*[./_].*" name != null;

  encodeNodeName =
    name:
    if needsEncoding name then
      lib.removeSuffix "\n" (
        readFile (
          pkgs.runCommand "encoded-node-${lib.strings.sanitizeDerivationName name}" { } ''
            ${getExe pkgs.jdk} ${./gen.java} --directory ${lib.escapeShellArg name} > "$out"
          ''
        )
      )
    else
      name;

  flattenPrefs =
    prefsPath: tree:
    let
      values = lib.attrValues tree;

      entries = lib.filterAttrs (_: value: isString value) tree;

      children = lib.filterAttrs (_: value: isAttrs value) tree;

      childPrefs = lib.concatMapAttrs (
        name: value: flattenPrefs (concatPath prefsPath (encodeNodeName name)) value
      ) children;
    in
    assert lib.all (value: isString value || isAttrs value) values;

    (lib.optionalAttrs (entries != { } && prefsPath != "") {
      "${prefsPath}" = entries;
    })
    // childPrefs;

  parentPaths =
    prefsPath:
    let
      parts = lib.filter (x: x != "") (lib.splitString "/" prefsPath);

      prefixes = foldl' (
        acc: part:
        acc
        ++ [
          (if acc == [ ] then part else "${lib.last acc}/${part}")
        ]
      ) [ ] parts;
    in
    lib.init prefixes;

  entriesToXml =
    entries:
    lib.concatStringsSep "\n  " (
      lib.mapAttrsToList (
        key: value: "<entry key=\"${lib.escapeXML key}\" value=\"${lib.escapeXML value}\"/>"
      ) entries
    );

  prefsToXml = entries: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">
    <map MAP_XML_VERSION="1.0">
      ${entriesToXml entries}
    </map>
  '';
}
