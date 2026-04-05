# Custom Extensions Guide

This guide explains how to add custom Burp Suite extensions from GitHub or other sources to your NixOS/Home Manager configuration.

## Overview

The module now supports two types of extensions:

1. **Built-in Extensions** - From the PortSwigger BApp store (existing behavior)
2. **Custom Extensions** - From GitHub or other sources (new feature)

## Using Custom Extensions

For custom extensions, you need to provide:

- `package` - Either:
  - A direct JAR file from `fetchurl` or `fetchFromGitHub`
  - A full derivation package
- `uuid` - A unique identifier (use UUID4), empty string by default
- `serialversion` - Version number (default is "1" for custom extensions)
- `extensiontype` - Language type: `"1"` (Java), `"2"` (Python), or `"3"` (Ruby)
- `entrypoint` - Only required if your package is a derivation without `BappManifest.bmf`

## Quick Example: Direct JAR from GitHub

The simplest way - just fetch the JAR directly:

```nix
programs.burp = {
  enable = true;

  extensions = {
    "my-extension" = {
      enable = true;

      package = pkgs.fetchurl {
        url = "https://github.com/username/repo/releases/download/v1.0.0/extension.jar";
        hash = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=";
      };

      extensiontype = "1";  # 1 = Java, 2 = Python, 3 = Ruby
    };
  };
};
```

## Example: JAR from GitHub Repository

```nix
extensions = {
  "custom-tool" = {
    enable = true;

    package = pkgs.fetchFromGitHub {
      owner = "username";
      repo = "burp-extension";
      rev = "v1.0.0";
      hash = "sha256-YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY=";
      # Optional: if JAR is in a subdirectory
      postFetch = ''
        mkdir -p $out
        cp $out/releases/extension.jar $out/
      '';
    };

    extensiontype = "1";
  };
};
```

## Built Extensions (Full Derivation)

If you need to build from source or do more complex setup:

```nix
extensions = {
  "complex-extension" = {
    enable = true;

    package = pkgs.stdenvNoCC.mkDerivation {
      pname = "complex-extension";
      version = "2.0.0";

      src = pkgs.fetchFromGitHub {
        owner = "author";
        repo = "burp-ext";
        rev = "v2.0.0";
        hash = "sha256-...=";
      };

      buildPhase = ''
        mvn clean package
      '';

      installPhase = ''
        mkdir -p $out/lib/complex-extension
        cp target/extension.jar $out/lib/complex-extension/
      '';
    };

    extensiontype = "1";
    # Only needed if no BappManifest.bmf
    entrypoint = "extension.jar";
  };
};
```

## With Custom Settings

```nix
extensions = {
  "configured-extension" = {
    enable = true;

    package = pkgs.fetchurl {
      url = "https://github.com/dev/plugin/releases/download/1.5.0/plugin.jar";
      hash = "sha256-ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ=";
    };

    extensiontype = "1";

    # Extension-specific preferences (Java Preferences API)
    settings = {
      "apiKey" = "your-key";
      "enableFeature" = "true";
    };
  };
};
```

## Non-loaded Extension

Install but don't auto-load:

```nix
extensions = {
  "optional-extension" = {
    enable = true;
    loaded = false;  # Won't load on startup

    package = pkgs.fetchurl {
      url = "https://github.com/contrib/ext/releases/download/1.0/extension.jar";
      hash = "sha256-WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW=";
    };

    extensiontype = "1";
  };
};
```

## How Extension Resolution Works

1. **Direct JAR files** (from `fetchurl`/`fetchFromGitHub`):

   - Package path is used directly as the extension file
   - Custom extensiontype is required

2. **Full derivations** (with `pname`):
   - Looks for `$package/lib/$pname/`
   - If no `entrypoint` specified, tries to parse `BappManifest.bmf`
   - Uses custom metadata if provided, otherwise uses `pkg.passthru.burp`

## Finding Extensions

### Get the Download Hash

For `fetchurl`:

```bash
nix hash file <path-to-jar>
```

For `fetchFromGitHub`:

```bash
nix flake prefetch github:owner/repo/ref
```

Or let Nix tell you:

```bash
# Set hash = "" and try to build
nix build -L 2>&1 | grep "got:"
```

## Troubleshooting

### "Hash mismatch"

Recalculate the hash using the methods above and update your config.

### "Missing EntryPoint in extension"

You need to either:

1. Provide `entrypoint = "filename.jar";`
2. Or use a full derivation that includes `BappManifest.bmf`

### "Unsupported Burp extensiontype"

`extensiontype` must be one of:

- `"1"` for Java
- `"2"` for Python
- `"3"` for Ruby

### Extension not loading

Check:

1. `enable = true`
2. `loaded` is not `false` (defaults to `true`)
3. The JAR file path/hash is correct
4. Metadata is valid (uuid, serialversion, extensiontype)

## Built-in vs Custom Extensions

You can mix both in the same config:

```nix
extensions = {
  # Built-in (original method)
  "403-bypasser".enable = true;
  "param-miner".enable = true;

  # Custom (new)
  "my-tool" = {
    enable = true;
    package = pkgs.fetchurl { /* ... */ };
    extensiontype = "1";
  };
};
```
