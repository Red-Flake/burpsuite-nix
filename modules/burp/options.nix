{
  lib,
  pkgs,
  burpPackages,
}:

let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    types
    literalExpression
    ;

  packageName = types.str // {
    description = "package name";
  };

  extensionPackage = types.package // {
    description = "extension package";
  };

  extensionModule = types.submoduleWith {
    shorthandOnlyDefinesConfig = false;
    modules = [
      ({ dagName, ... }: {
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
          type = types.coercedTo packageName (
            pkgName: burpPackages.${pkgs.stdenv.hostPlatform.system}.${pkgName}
          ) extensionPackage;

          default = burpPackages.${pkgs.stdenv.hostPlatform.system}.${dagName};

          defaultText = literalExpression ''
            burpPackages.\${pkgs.stdenv.hostPlatform.system}.<extension-name>
          '';

          description = ''
            Nix package for this extension. Can be:
            - A package name string (resolved from burpPackages)
            - A full derivation
            - A fetchurl/fetchFromGitHub result for the JAR file directly
          '';
        };

        options.uuid = mkOption {
          type = types.str;
          default = "";
          description = ''
            UUID for custom extensions fetched from sources other than the BApp store.
            Required when using custom GitHub extensions.
          '';
        };

        options.serialversion = mkOption {
          type = types.str;
          default = "1";
          description = ''
            Serial version for custom extensions fetched from sources other than the BApp store.
            Required when using custom GitHub extensions.
          '';
        };

        options.extensiontype = mkOption {
          type = types.nullOr (
            types.enum [
              "1"
              "2"
              "3"
            ]
          );
          default = null;
          description = ''
            Extension type for custom extensions fetched from sources other than the BApp store.
            Values: "1" for Java, "2" for Python, "3" for Ruby.
            Required when using custom GitHub extensions.
          '';
        };

        options.entrypoint = mkOption {
          type = types.str;
          default = "";
          description = ''
            Override the entrypoint for the extension (JAR file name relative to the lib directory).
            Only needed for custom extensions that don't have BappManifest.bmf.
          '';
        };

        options.settings = mkOption {
          inherit (pkgs.formats.json { }) type;
          default = { };
          description = ''
            Sets preferences for this extension via the Java Preferences API.
            Options added here are only applied, if the prefs file doesn't already exist.
          '';
        };
      })
    ];
  };
in
{
  options.programs.burp = {
    enable = mkEnableOption "Burp Suite";

    proEdition = mkEnableOption "the Pro edition";

    package = mkPackageOption pkgs "burpsuite" { };

    cliArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional command line arguments to pass to Burp";
    };

    finalPackage = mkOption {
      type = types.package;
      visible = false;
      readOnly = true;
    };

    wordlists = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = ''
        Mapping of wordlist names to paths.
        These paths will be mounted at /lists/<name> in the Burp sandbox.
      '';
    };

    enableJython = mkEnableOption "Jython support";

    enableJruby = mkEnableOption "Jruby support";

    settings = mkOption {
      inherit (pkgs.formats.json { }) type;
      default = { };
      description = ''
        Overrides for Burp config.json (deep merged).
        Options added here are always wrapped in `user_options`.
      '';
    };

    preferences = mkOption {
      inherit (pkgs.formats.json { }) type;
      default = { };
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
      inherit (pkgs.formats.json { }) type;
      internal = true;
      readOnly = true;
    };

    extensions = mkOption {
      type = lib.hm.types.dagOf extensionModule;
      default = { };
      description = ''
        Attribute set of Burp extensions.
        Extension names like "403-bypasser" are resolved automatically from
        `burpPackages.''${pkgs.stdenv.hostPlatform.system}` without needing to reference the input.
        Extension ordering can be controlled with lib.hm.dag.entryBefore and lib.hm.dag.entryAfter.
      '';
    };
  };
}
