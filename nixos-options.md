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



## programs\.burp\.edition

Burp config variants: Community / Pro\.
It defaults to Community but you can set both\.
This will create the corresponding default files UserConfig\<variant>\.json\.



*Type:*
list of (one of “Community”, “Pro”)



*Default:*

```nix
[
  "Community"
]
```

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.extensions



List of Burp extensions\.
Strings like “403-bypasser” are resolved automatically from
` burpPackages.${pkgs.stdenv.hostPlatform.system} ` without needing to reference the input\.



*Type:*
(attribute set of (submodule)) or (list of string) convertible to it



*Default:*
` { } `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.extensions\.\<name>\.package



Nix package for this extension



*Type:*
package



*Default:*
` burpPackages.${pkgs.stdenv.hostPlatform.system}.${name} `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.extensions\.\<name>\.loaded



Whether this extension should be enabled



*Type:*
boolean



*Default:*
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


