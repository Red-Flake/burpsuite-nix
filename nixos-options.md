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

Burp config variants: generates UserConfig\<variant>\.json\. Possible options: Community and Pro



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



List of Burp extension packages (Nix derivations)\.



*Type:*
list of (package or (attribute set))



*Default:*
` [ ] `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)



## programs\.burp\.settings



Overrides for Burp’s config\.json (deep merged)\.



*Type:*
attribute set



*Default:*
` { } `

*Declared by:*
 - [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp\.nix)


