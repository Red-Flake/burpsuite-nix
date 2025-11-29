{
  config,
  lib,
  pkgs,
  burpPackages,
  ...
}:

let
  cfg = config.programs.burp;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    recursiveUpdate
    ;

  # Resolve strings like "403-bypasser" into:
  # burpPackages.${pkgs.stdenv.hostPlatform.system}."403-bypasser"
  normalizeExtension =
    ext:
    if builtins.isString ext then
      # If it's a string, look it up in burpPackages
      burpPackages.${pkgs.stdenv.hostPlatform.system}.${ext}
    else if builtins.isAttrs ext && builtins.hasAttr "package" ext then
      let
        pkg = ext.package;
      in
      if builtins.isString pkg then
        # Replace the string with the proper package from burpPackages
        ext // { package = burpPackages.${pkgs.stdenv.hostPlatform.system}.${pkg}; }
      else
        # Already a derivation
        ext
    else
      # Already a derivation
      ext;

  normalizedExtensions = map normalizeExtension cfg.extensions;

  defaultConfig = builtins.fromJSON (builtins.readFile ../data/config.json);

  mkExtensionEntry =
    ext:
    let
      pkg = if builtins.isAttrs ext && builtins.hasAttr "package" ext then ext.package else ext;

      loaded = if builtins.isAttrs ext && builtins.hasAttr "loaded" ext then ext.loaded else true;

      manifestContent = builtins.readFile "${pkg}/lib/${pkg.pname}/BappManifest.bmf";

      entrypoint = lib.trim (
        lib.removePrefix "EntryPoint:" (
          lib.findFirst (l: lib.hasPrefix "EntryPoint:" l) (throw "Missing EntryPoint in ${pkg.pname}") (
            lib.splitString "\n" manifestContent
          )
        )
      );
    in
    {
      bapp_serial_version = pkg.passthru.burp.serialversion;
      bapp_uuid = pkg.passthru.burp.uuid;
      errors = "ui";
      extension_file = "${pkg}/lib/${pkg.pname}/${entrypoint}";
      extension_type =
        if pkg.passthru.burp.extensiontype == "1" then
          "java"
        else if pkg.passthru.burp.extensiontype == "2" then
          "python"
        else if pkg.passthru.burp.extensiontype == "3" then
          "ruby"
        else
          throw "Unsupported Burp extensiontype: ${pkg.passthru.burp.extensiontype}";
      loaded = loaded;
      name = pkg.passthru.burp.name;
      output = "ui";
    };

  hasPythonExt = lib.any (
    ext:
    let
      pkg = if builtins.isAttrs ext && builtins.hasAttr "package" ext then ext.package else ext;
    in
    pkg.passthru.burp.extensiontype == "2"
  ) normalizedExtensions;

  hasRubyExt = lib.any (
    ext:
    let
      pkg = if builtins.isAttrs ext && builtins.hasAttr "package" ext then ext.package else ext;
    in
    pkg.passthru.burp.extensiontype == "3"
  ) normalizedExtensions;

  extraInterpreterConfig =
    lib.recursiveUpdate
      (
        if hasPythonExt then
          {
            user_options.extender.python.location_of_jython_standalone_jar_file = "${pkgs.jython}/jython.jar";
          }
        else
          { }
      )
      (
        if hasRubyExt then
          {
            user_options.extender.ruby.location_of_jruby_jar_file = "${pkgs.fetchurl {
              url = "https://repo1.maven.org/maven2/org/jruby/jruby-complete/10.0.2.0/jruby-complete-10.0.2.0.jar";
              hash = "sha256-xaVKvuLAKp/3+gskvssncourqREFuXzl2ZLoWGQm+Iw=";
            }}";
          }
        else
          { }
      );

in
{
  options.programs.burp = {
    enable = mkEnableOption "Burp Suite";

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Overrides for Burp config.json (deep merged). Options added here are always wrapped in `user_options`.";
    };

    extensions = mkOption {
      type = types.listOf (
        types.oneOf [
          types.package
          types.attrs
          types.str # strings are resolved to packages
        ]
      );
      default = [ ];
      description = ''
        List of Burp extensions.
        Strings like "403-bypasser" are resolved automatically from
        `burpPackages.$\{pkgs.stdenv.hostPlatform.system}` without needing to reference the Input.
      '';
    };

    edition = mkOption {
      type = types.listOf types.str;
      default = [ "Community" ];
      description = "Burp config variants: Community / Pro. It defaults to Community but you can set both. This will create the corresponding default files UserConfig\<variant>\.json.";
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      map (
        ext: if builtins.isAttrs ext && builtins.hasAttr "package" ext then ext.package else ext
      ) normalizedExtensions
      ++ lib.optional hasPythonExt pkgs.jython
      ++ lib.optional hasRubyExt pkgs.jruby;

    home.file = lib.listToAttrs (
      map (variant: {
        name = ".BurpSuite/UserConfig${variant}.json";
        value = {
          text = builtins.toJSON (
            recursiveUpdate defaultConfig (
              recursiveUpdate extraInterpreterConfig {
                user_options = recursiveUpdate cfg.settings {
                  extender.extensions = map mkExtensionEntry normalizedExtensions;
                };
              }
            )
          );
          force = true;
        };
      }) cfg.edition
    );
  };
}
