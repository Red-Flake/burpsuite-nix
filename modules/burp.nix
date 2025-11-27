{
  config,
  lib,
  pkgs,
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

  # Default config that was generated after the first start of BurpSuite
  # Changed automatically_update_bapps_on_startup to false, because it is handeled by Nix
  # All config options can be found here in the User Section: https://gist.github.com/asadasivan/9d8f5be51ce08745c2bd50f69296b1ab#file-burp_defaults_combined-json-L513
  defaultConfig = builtins.fromJSON (builtins.readFile ../defaults/config.json);

  # Convert extension package → Burp JSON entry
  mkExtensionEntry =
    ext:
    let
      pkg = if builtins.isAttrs ext && builtins.hasAttr "package" ext then ext.package else ext;
      loaded = if builtins.isAttrs ext && builtins.hasAttr "loaded" ext then ext.loaded else true;
    in
    {
      bapp_serial_version = pkg.passthru.burp.serialversion;
      bapp_uuid = pkg.passthru.burp.uuid;
      errors = "ui";
      extension_file =
        if pkg.passthru.burp.extensiontype == "1" then
          "${pkg}/lib/${pkg.pname}/${pkg.pname}.jar"
        else if pkg.passthru.burp.extensiontype == "2" then
          "${pkg}/lib/${pkg.pname}/${pkg.pname}.py"
        else if pkg.passthru.burp.extensiontype == "3" then
          "${pkg}/lib/${pkg.pname}/${pkg.pname}.rb"
        else
          throw "Unsupported Burp extensiontype: ${pkg.passthru.burp.extensiontype}";
      extension_type =
        if pkg.passthru.burp.extensiontype == "1" then
          "java"
        else if pkg.passthru.burp.extensiontype == "2" then
          "python"
        else if pkg.passthru.burp.extensiontype == "3" then
          "ruby"
        else
          "unknown";
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
  ) cfg.extensions;

  hasRubyExt = lib.any (
    ext:
    let
      pkg = if builtins.isAttrs ext && builtins.hasAttr "package" ext then ext.package else ext;
    in
    pkg.passthru.burp.extensiontype == "3"
  ) cfg.extensions;

  extraPkgs =
    (lib.optionals hasPythonExt [ pkgs.jython ]) ++ (lib.optionals hasRubyExt [ pkgs.jruby ]);

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
      description = "Overrides for Burp's config.json (deep merged).";
    };

    extensions = mkOption {
      type = types.listOf (
        types.oneOf [
          types.package # accepts derivations
          types.attrs # accepts { package = …; loaded = … }
        ]
      );
      default = [ ];
      description = "List of Burp extension packages (Nix derivations).";
    };

    edition = mkOption {
      type = types.listOf types.str;
      default = [ "Community" ];
      description = "Burp config variants: generates UserConfig<variant>.json. Possible options: Community and Pro";
    };

    darkMode = mkOption {
      type = types.bool;
      default = false;
      description = "Enable dark mode in Burp Suite UI.";
    };
  };

  config = mkIf cfg.enable {
    # Extracts the package out of attrs
    home.packages =
      map (
        ext: if builtins.isAttrs ext && builtins.hasAttr "package" ext then ext.package else ext
      ) cfg.extensions
      ++ lib.optional hasPythonExt pkgs.jython
      ++ lib.optional hasRubyExt pkgs.jruby;

    # Generate a config file for each variant
    home.file = lib.listToAttrs (
      map (variant: {
        name = ".BurpSuite/UserConfig${variant}.json";
        value = {
          text = builtins.toJSON (
            recursiveUpdate defaultConfig (
              recursiveUpdate {
                user_options.extender.extensions = map mkExtensionEntry cfg.extensions;
                user_options.display.user_interface.look_and_feel = if cfg.darkMode then "Dark" else null;
              } (recursiveUpdate extraInterpreterConfig cfg.settings)
            )
          );
          force = true;
        };
      }) cfg.edition
    );
  };
}
