{
  config,
  lib,
  pkgs,
  burpPackages,
  ...
}:
let
  inherit (lib)
    filter
    importJSON
    mapAttrsToList
    mkIf
    optional
    optionalAttrs
    ;

  inherit (lib.strings) toJSON;

  cfg = config.programs.burp;

  helpers = import ./lib.nix {
    inherit lib;
  };

  inherit (helpers)
    extTypes
    isDirectJar
    getExtensionType
    getExtensionName
    recursiveMerge
    mkExtensionEntry
    ;

  sortedExtensions = lib.hm.dag.topoSort cfg.extensions;

  enabledExtensions =
    if sortedExtensions ? result then
      filter (ext: ext.enable) (map (entry: entry.data) sortedExtensions.result)
    else
      throw "Dependency cycle in Burp extensions: ${builtins.toJSON sortedExtensions}";
in
{

  imports = [
    (import ./options.nix {
      inherit lib pkgs burpPackages;
    })
  ];

  config = mkIf cfg.enable {
    programs.burp = {
      enableJython = lib.mkDefault (
        lib.any (ext: getExtensionType ext == extTypes.python) enabledExtensions
      );
      enableJruby = lib.mkDefault (
        lib.any (ext: getExtensionType ext == extTypes.ruby) enabledExtensions
      );
      finalPackage = cfg.package.override (
        old:
        (
          if lib.hasAttr "iconName" old then
            { iconName = if cfg.proEdition then "pro" else "community"; }
          else
            { }
        )
        // {
          buildFHSEnv =
            args:
            old.buildFHSEnv (
              args
              // {
                runScript =
                  (args.runScript or "")
                  + (lib.strings.optionalString (cfg.cliArgs != [ ]) (" " + lib.strings.escapeShellArgs cfg.cliArgs));
                extraBwrapArgs =
                  (args.extraBwrapArgs or [ ])
                  ++ mapAttrsToList (dst: src: "--ro-bind ${src} /lists/${dst}") cfg.wordlists;
              }
            );
        }
      );
      finalSettings = recursiveMerge [
        (importJSON ../../data/config.json)
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
      optional (cfg.preferences != { } || cfg.license != "") {
        burp = recursiveMerge [
          cfg.preferences

          (optionalAttrs (cfg.license != "") {
            license1 = cfg.license;
          })

          {
            # Hardcoded pkcs12 file with the private key and certificate
            caCert = "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";
          }

          (recursiveMerge (
            mapAttrsToList (
              _: entry:
              let
                ext = entry.data;
              in
              optionalAttrs (ext.enable && ext.settings != { }) {
                extensions = {
                  "${"_${getExtensionName ext}"}" = ext.settings;
                };
              }
            ) cfg.extensions
          ))
        ];
      }
    );

    programs.firefox.policies = mkIf config.programs.firefox.enable {
      Certificates = {
        ImportEnterpriseRoots = true;
        Install = [ "~/.BurpSuite/cacert.der" ];
      };
    };

    home = {
      packages = [
        cfg.finalPackage
      ]
      ++ map (ext: ext.package) (filter (ext: !isDirectJar ext.package) enabledExtensions);

      file.".BurpSuite/UserConfig.json" = {
        text = toJSON cfg.finalSettings;
        force = true;
      };
      # Expose the hardcoded cacert
      file.".BurpSuite/cacert.der".source = ../../data/cacert.der;
    };
  };
}
