## programs\.burp\.enable



Whether to enable Burp Suite\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.enableJruby



Whether to enable Jruby support\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.enableJython



Whether to enable Jython suppport\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.package



The burpsuite package to use\.



*Type:*
package



*Default:*
` pkgs.burpsuite `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.cliArgs

Additional command line arguments to pass to Burp



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.extensions



Attribute set of Burp extensions\.
Extension names like “403-bypasser” are resolved automatically from
` burpPackages.${pkgs.stdenv.hostPlatform.system} ` without needing to reference the input\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.extensions\.\<name>\.enable



Whether to enable this extension\.
Disabled extensions won’t be present in the generated config\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.extensions\.\<name>\.package



Nix package for this extension, or a package name looked up in the default set



*Type:*
extension package or package name convertible to it



*Default:*
` burpPackages.${pkgs.stdenv.hostPlatform.system}.${_module.args.name} `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.extensions\.\<name>\.loaded



Whether to automatically load this extension on Burp startup\.
Unloaded extensions will still be present, but have to be manually loaded\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.proEdition



Whether to enable the Pro edition\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.settings



Overrides for Burp config\.json (deep merged)\.
Options added here are always wrapped in ` user_options `\.



*Type:*
JSON value



*Default:*
` { } `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.wordlists



Mapping of wordlist names to paths\.
These paths will be mounted at /lists/\<name> in the Burp sandbox\.



*Type:*
attribute set of absolute path



*Default:*
` { } `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.java\.userPrefs



Java user preferences as nested attribute sets\. Each top-level key is a preference path, with nested key-value pairs for individual preferences\.



*Type:*
attribute set of attribute set of string



*Default:*
` { } `



*Example:*

```nix
{
  burp = {
    "global.suite.deviceId" = "vyogc3mm6uedd3ntpi58";
  };
  "burp/extensions/_HTTP Request Smuggler" = {
    "global.suite.deviceId" = "vyogc3mm6uedd3ntpi58";
  };
}
```

*Declared by:*
 - [modules/javaUserPrefs/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/javaUserPrefs/default\.nix)


