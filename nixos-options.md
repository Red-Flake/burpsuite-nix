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



## programs\.burp\.edition

Burp config variants: Community / Pro\. It defaults to Community but you can set both\. This will create the corresponding default files UserConfig\<variant>\.json\.



*Type:*
list of string



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
` burpPackages.$\{pkgs.stdenv.hostPlatform.system} ` without needing to reference the Input\.



*Type:*
list of (package or (attribute set) or string)



*Default:*
` [ ] `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.settings



Overrides for Burp config\.json (deep merged)\. Options added here are always wrapped in ` user_options `\.



*Type:*
attribute set



*Default:*
` { } `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)


