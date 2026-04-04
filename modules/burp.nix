{
  config,
  lib,
  pkgs,
  burpPackages,
  ...
}: let
  inherit
    (lib)
    all
    any
    attrsToList
    attrValues
    concatLists
    filter
    findFirst
    hasAttr
    hasPrefix
    head
    importJSON
    isAttrs
    isList
    last
    literalExpression
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optional
    optionalAttrs
    pipe
    readFile
    removePrefix
    splitString
    tail
    trim
    types
    unique
    zipAttrsWith
    ;

  inherit (lib.strings) toJSON;

  # https://stackoverflow.com/a/54505212
  recursiveMerge = let
    f = attrPath:
      zipAttrsWith (
        n: values:
          if tail values == []
          then head values
          else if all isList values
          then unique (concatLists values)
          else if all isAttrs values
          then f (attrPath ++ [n]) values
          else last values
      );
  in
    f [];

  cfg = config.programs.burp;

  enabledExtensions = pipe cfg.extensions [
    attrValues
    (filter (ext: ext.enable))
  ];

  extTypes = {
    java = "1";
    python = "2";
    ruby = "3";
  };

  editionName =
    if cfg.proEdition
    then "Pro"
    else "Community";

  packageName =
    types.str
    // {
      description = "package name";
    };

  extensionPackage =
    types.package
    // {
      description = "extension package";
    };

  extensionModule = types.submoduleWith {
    shorthandOnlyDefinesConfig = false;
    modules = [
      ({config, ...}: {
        options.enable = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to enable this extension.
            Disabled extensions won't be present in the generated config.
          '';
        };

        options.loaded = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to automatically load this extension on Burp startup.
            Unloaded extensions will still be present, but have to be manually loaded.
          '';
        };

        options.package = mkOption {
          type =
            types.coercedTo packageName (
              pkgName: burpPackages.${pkgs.stdenv.hostPlatform.system}.${pkgName}
            )
            extensionPackage;
          default = burpPackages.${pkgs.stdenv.hostPlatform.system}.${config._module.args.name};
          defaultText = literalExpression "burpPackages.\${pkgs.stdenv.hostPlatform.system}.\${_module.args.name}";
          description = "Nix package for this extension, or a package name looked up in the default set";
        };

        options.settings = mkOption {
          inherit (pkgs.formats.json {}) type;
          default = {};
          description = ''
            Sets preferences for this extension via the Java Preferences API.
            Options added here are only applied, if the prefs file doesn't already exist.
          '';
        };
      })
    ];
  };

  mkExtensionEntry = ext: let
    pkg = ext.package;
    dir = "${pkg}/lib/${pkg.pname}";
    entrypoint = "EntryPoint:";
  in {
    bapp_serial_version = pkg.passthru.burp.serialversion;
    bapp_uuid = pkg.passthru.burp.uuid;

    extension_file = pipe "${dir}/BappManifest.bmf" [
      readFile
      (splitString "\n")
      (findFirst (hasPrefix entrypoint) (throw "Missing EntryPoint in ${pkg.name}"))
      (removePrefix entrypoint)
      trim
      (file: "${dir}/${file}")
    ];

    extension_type = pipe extTypes [
      attrsToList
      (findFirst (x: x.value == pkg.passthru.burp.extensiontype) (
        throw "Unsupported Burp extensiontype: ${pkg.passthru.burp.extensiontype}"
      ))
      (x: x.name)
    ];

    inherit (ext) loaded;
    inherit (pkg.passthru.burp) name;

    output = "ui";
    errors = "ui";
  };
in {
  options.programs.burp = {
    enable = mkEnableOption "Burp Suite";

    proEdition = mkEnableOption "the Pro edition";

    package = mkPackageOption pkgs "burpsuite" {};

    cliArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional command line arguments to pass to Burp";
    };

    finalPackage = mkOption {
      type = types.package;
      visible = false;
      readOnly = true;

      default = cfg.package.override (
        old:
          (
            if hasAttr "proEdition" old
            then {inherit (cfg) proEdition;}
            else {}
          )
          // {
            buildFHSEnv = args:
              old.buildFHSEnv (
                args
                // {
                  runScript =
                    (args.runScript or "")
                    + (lib.strings.optionalString (cfg.cliArgs != []) (" " + lib.strings.escapeShellArgs cfg.cliArgs));
                  extraBwrapArgs =
                    (args.extraBwrapArgs or [])
                    ++ mapAttrsToList (dst: src: "--ro-bind ${src} /lists/${dst}") cfg.wordlists;
                }
              );
          }
      );
    };

    wordlists = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = ''
        Mapping of wordlist names to paths.
        These paths will be mounted at /lists/<name> in the Burp sandbox.
      '';
    };

    enableJython =
      mkEnableOption "Jython suppport"
      // {
        default = any (ext: ext.package.passthru.burp.extensiontype == extTypes.python) enabledExtensions;
      };

    enableJruby =
      mkEnableOption "Jruby support"
      // {
        default = any (ext: ext.package.passthru.burp.extensiontype == extTypes.ruby) enabledExtensions;
      };

    settings = mkOption {
      inherit (pkgs.formats.json {}) type;
      default = {};
      description = ''
        Overrides for Burp config.json (deep merged).
        Options added here are always wrapped in `user_options`.
      '';
    };

    preferences = mkOption {
      inherit (pkgs.formats.json {}) type;
      default = {};
      description = ''
        Sets preferences set by Burpsuite via the Java Preferences API.
        Options added here are only applied, if the prefs file doesn't already exist.
      '';
    };

    license = mkOption {
      type = types.str;
      default = "";
      description = ''
        Burp Suite license key.
        When set, will be added to Java preferences as license1.
      '';
    };

    finalSettings = mkOption {
      inherit (pkgs.formats.json {}) type;
      internal = true;
      readOnly = true;
    };

    extensions = mkOption {
      type = types.attrsOf extensionModule;
      default = {};
      description = ''
        Attribute set of Burp extensions.
        Extension names like "403-bypasser" are resolved automatically from
        `burpPackages.''${pkgs.stdenv.hostPlatform.system}` without needing to reference the input.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.burp = {
      finalSettings = recursiveMerge [
        (importJSON ../data/config.json)
        {
          user_options = recursiveMerge [
            {
              extender = recursiveMerge [
                {
                  extensions = map mkExtensionEntry enabledExtensions;
                }

                (optionalAttrs cfg.enableJython {
                  python.location_of_jython_standalone_jar_file = "${pkgs.jython}/jython.jar";
                })

                (optionalAttrs cfg.enableJruby {
                  ruby.location_of_jruby_jar_file = pkgs.fetchurl {
                    url = "https://repo1.maven.org/maven2/org/jruby/jruby-complete/10.0.4.0/jruby-complete-10.0.4.0.jar";
                    hash = "sha256-5p9Hcdd7ZdKPqb15vQpmOwKaOFgLHtlMmrWJ56YyiP8=";
                  };
                })
              ];
            }

            cfg.settings
          ];
        }
      ];
    };

    programs.java.userPrefs = recursiveMerge (
      optional (cfg.preferences != {} || cfg.license != "") {
        "burp" = recursiveMerge [
          cfg.preferences
          (optionalAttrs (cfg.license != "") {
            license1 = cfg.license;
          })
        ];
      }
      ++ mapAttrsToList (
        extName: ext:
          optionalAttrs (ext.enable && ext.settings != {}) {
            "burp/extensions/_${ext.package.passthru.burp.name}" = ext.settings;
          }
      )
      cfg.extensions
    );

    home = {
      packages =
        [
          cfg.finalPackage
        ]
        ++ map (ext: ext.package) enabledExtensions
        ++ optional cfg.enableJython pkgs.jython
        ++ optional cfg.enableJruby pkgs.jruby;

      file.".BurpSuite/UserConfig${editionName}.json" = {
        text = toJSON cfg.finalSettings;
        force = true;
      };
    };
  };
}
