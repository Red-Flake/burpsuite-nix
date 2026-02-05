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



## programs\.burp\.extensions



List of Burp extensions\.
Strings like “403-bypasser” are resolved automatically from
` burpPackages.${pkgs.stdenv.hostPlatform.system} ` without needing to reference the input\.



*Type:*
(attribute set of (submodule)) or (list of (package name or (extension module))) convertible to it



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
` burpPackages.${pkgs.stdenv.hostPlatform.system}.${name} `

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



## programs\.burp\.extensions\.\<name>\.priority



Priority of this module\.
Modules are loaded in order of ascending priority,
so the lowest priority is loaded first\.



*Type:*
signed integer



*Default:*
If using the list shorthand: 1000 · 1-based list index\.
Otherwise, priorities must be set manually\.

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


