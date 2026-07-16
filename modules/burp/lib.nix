{ lib, ... }:

let
  inherit (lib)
    attrsToList
    findFirst
    hasPrefix
    pipe
    readFile
    removePrefix
    splitString
    trim
    zipAttrsWith
    tail
    head
    isList
    concatLists
    unique
    all
    isAttrs
    isDerivation
    hasSuffix
    removeSuffix
    last
    isPath
    ;

  # https://stackoverflow.com/a/54505212
  recursiveMerge =
    let
      f =
        attrPath:
        zipAttrsWith (
          n: values:
          if tail values == [ ] then
            head values
          else if all isList values then
            unique (concatLists values)
          else if all isAttrs values then
            f (attrPath ++ [ n ]) values
          else
            last values
        );
    in
    f [ ];

  extTypes = {
    java = "1";
    python = "2";
    ruby = "3";
  };

  # Check if an extension is a custom extension (not from BApp store)
  isCustomExtension = ext: ext.extensiontype != null;

  # Check if a package is a direct JAR file (from fetchurl/fetchFromGitHub)
  isDirectJar =
    pkg: isPath pkg || (isDerivation pkg && pkg.name != null && (hasSuffix ".jar" pkg.name));

  # Get the extension type from either custom metadata or package passthru
  getExtensionType =
    ext: if isCustomExtension ext then ext.extensiontype else ext.package.passthru.burp.extensiontype;

  # Get the extension name from either direct JAR, custom metadata, or package passthru
  getExtensionName =
    ext:
    if isDirectJar ext.package then
      removeSuffix ".jar" ext.package.name
    else if isCustomExtension ext then
      ext.package.name
    else
      ext.package.passthru.burp.name;

  mkExtensionEntry =
    ext:
    let
      pkg = ext.package;
      entrypoint = "EntryPoint:";

      # Build directory path - either lib subdir for full packages or direct for JAR files
      dir = if isDirectJar pkg then dirOf (toString pkg) else "${pkg}/lib/${pkg.pname}";

      # Get entrypoint - for direct JARs it's just the filename, otherwise parse or use override
      getEntrypoint =
        if isDirectJar pkg then
          toString pkg
        else if ext.entrypoint != "" then
          "${dir}/${ext.entrypoint}"
        else
          pipe "${dir}/BappManifest.bmf" [
            readFile
            (splitString "\n")
            (findFirst (hasPrefix entrypoint) (
              throw "Missing EntryPoint in ${pkg.name} and no custom entrypoint provided"
            ))
            (removePrefix entrypoint)
            trim
            (file: "${dir}/${file}")
          ];

      # For custom extensions, use provided metadata, otherwise use passthru.burp
      getSerialVersion =
        if isCustomExtension ext then ext.serialversion else pkg.passthru.burp.serialversion;

      getUuid = if isCustomExtension ext then ext.uuid else pkg.passthru.burp.uuid;
    in
    {
      bapp_serial_version = getSerialVersion;
      bapp_uuid = getUuid;

      extension_file = getEntrypoint;

      extension_type = pipe extTypes [
        attrsToList
        (findFirst (x: x.value == getExtensionType ext) (
          throw "Unsupported Burp extensiontype: ${getExtensionType ext}"
        ))
        (x: x.name)
      ];

      inherit (ext) loaded;
      name = getExtensionName ext;

      output = "ui";
      errors = "ui";
    };

in
{
  inherit
    extTypes
    isDirectJar
    getExtensionType
    getExtensionName
    recursiveMerge
    mkExtensionEntry
    ;
}
