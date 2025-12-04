{
  config,
  lib,
  pkgs,
  burpPackages,
  ...
}:
let
  inherit (lib)
    all
    allUnique
    any
    attrValues
    attrsToList
    concatLists
    filter
    findFirst
    flip
    hasPrefix
    head
    imap
    importJSON
    isAttrs
    isList
    last
    listToAttrs
    literalExpression
    literalMD
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalAttrs
    pipe
    readFile
    removePrefix
    sortOn
    splitString
    tail
    trim
    types
    unique
    zipAttrsWith
    ;

  inherit (lib.strings) toJSON;

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

  packageName = types.str // {
    description = "package name";
  };

  extensionPackage = types.package // {
    description = "extension package";
  };

  extensionModule =
    types.submodule {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to enable this extension.
            Disabled extensions won't be present in the generated config.
          '';
        };

        loaded = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to automatically load this extension on Burp startup.
            Unloaded extensions will still be present, but have to be manually loaded.
          '';
        };

        priority = mkOption {
          type = types.int;
          defaultText = literalMD ''
            If using the list shorthand: 1000 · 1-based list index.
            Otherwise, priorities must be set manually.
          '';
          description = ''
            Priority of this module.
            Modules are loaded in order of ascending priority,
            so the lowest priority is loaded first.
          '';
        };

        package = mkOption {
          type = types.coercedTo packageName (
            name: burpPackages.${pkgs.stdenv.hostPlatform.system}.${name}
          ) extensionPackage;
          defaultText = literalExpression "burpPackages.\${pkgs.stdenv.hostPlatform.system}.\${name}";
          description = "Nix package for this extension, or a package name looked up in the default set";
        };
      };
    }
    // {
      description = "extension module";
    };

  mkExtensionEntry =
    ext:
    let
      pkg = ext.package;
      dir = "${pkg}/lib/${pkg.pname}";
      entrypoint = "EntryPoint:";
    in
    {
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
in
{
  options.programs.burp = {
    enable = mkEnableOption "Burp Suite";

    enableJython = mkEnableOption "Jython suppport" // {
      default = any (ext: ext.package.passthru.burp.extensiontype == extTypes.python) enabledExtensions;
    };

    enableJruby = mkEnableOption "Jruby support" // {
      default = any (ext: ext.package.passthru.burp.extensiontype == extTypes.ruby) enabledExtensions;
    };

    settings = mkOption {
      inherit (pkgs.formats.json { }) type;
      default = { };
      description = ''
        Overrides for Burp config.json (deep merged).
        Options added here are always wrapped in `user_options`.
      '';
    };

    finalSettings = mkOption {
      inherit (pkgs.formats.json { }) type;
      internal = true;
      readOnly = true;
    };

    extensions = mkOption {
      type = types.coercedTo (types.listOf (types.either packageName extensionModule)) (flip pipe [
        (imap (
          i: x:
          recursiveMerge [
            { value.priority = 1000 * i; }
            (
              if isAttrs x then
                {
                  name = x.package.pname or x.package;
                  value = x;
                }
              else
                {
                  name = x;
                  value.package = x;
                }
            )
          ]
        ))
        listToAttrs
      ]) (types.attrsOf extensionModule);
      default = { };
      description = ''
        List of Burp extensions.
        Strings like "403-bypasser" are resolved automatically from
        `burpPackages.''${pkgs.stdenv.hostPlatform.system}` without needing to reference the input.
      '';
    };

    edition = mkOption {
      type = types.listOf (
        types.enum [
          "Community"
          "Pro"
        ]
      );
      default = [ "Community" ];
      description = ''
        Burp config variants: Community / Pro.
        It defaults to Community but you can set both.
        This will create the corresponding default files UserConfig<variant>.json.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pipe enabledExtensions [
          (map (x: x.priority))
          allUnique
        ];

        message = ''
          programs.burp.extensions: all priorities must be unique!
          If you're using the shorthand way of defining extensions as a list,
          please only do so once, otherwise the automatically generated priorities
          will conflict with eachother!
        '';
      }
    ];

    programs.burp = {
      finalSettings = recursiveMerge [
        (importJSON ../data/config.json)
        {
          user_options = recursiveMerge [
            {
              extender = recursiveMerge [
                {
                  extensions = pipe enabledExtensions [
                    (sortOn (x: x.priority))
                    (map mkExtensionEntry)
                  ];
                }

                (optionalAttrs cfg.enableJython {
                  python.location_of_jython_standalone_jar_file = "${pkgs.jython}/jython.jar";
                })

                (optionalAttrs cfg.enableJruby {
                  ruby.location_of_jruby_jar_file = pkgs.fetchurl {
                    url = "https://repo1.maven.org/maven2/org/jruby/jruby-complete/10.0.2.0/jruby-complete-10.0.2.0.jar";
                    hash = "sha256-xaVKvuLAKp/3+gskvssncourqREFuXzl2ZLoWGQm+Iw=";
                  };
                })
              ];
            }

            cfg.settings
          ];
        }
      ];
    };

    home = {
      packages =
        map (ext: ext.package) enabledExtensions
        ++ optional cfg.enableJython pkgs.jython
        ++ optional cfg.enableJruby pkgs.jruby;

      file = pipe cfg.edition [
        (map (variant: {
          name = ".BurpSuite/UserConfig${variant}.json";
          value = {
            text = toJSON cfg.finalSettings;
            force = true;
          };
        }))
        listToAttrs
      ];
    };
  };
}
