## programs\.burp\.enable

Whether to enable Burp Suite\.

_Type:_
boolean

_Default:_
`false`

_Example:_
`true`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.enableJruby

Whether to enable Jruby support\.

_Type:_
boolean

_Default:_
`false`

_Example:_
`true`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.enableJython

Whether to enable Jython suppport\.

_Type:_
boolean

_Default:_
`false`

_Example:_
`true`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.package

The burpsuite package to use\.

_Type:_
package

_Default:_
`pkgs.burpsuite`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.cliArgs

Additional command line arguments to pass to Burp

_Type:_
list of string

_Default:_
`[ ]`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.extensions

List of Burp extensions\.
Strings like “403-bypasser” are resolved automatically from
`burpPackages.${pkgs.stdenv.hostPlatform.system}` without needing to reference the input\.

_Type:_
(attribute set of (submodule)) or (list of (package name or (extension module))) convertible to it

_Default:_
`{ }`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.extensions\.\<name>\.enable

Whether to enable this extension\.
Disabled extensions won’t be present in the generated config\.

_Type:_
boolean

_Default:_
`true`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.extensions\.\<name>\.package

Nix package for this extension, or a package name looked up in the default set

_Type:_
extension package or package name convertible to it

_Default:_
`burpPackages.${pkgs.stdenv.hostPlatform.system}.${name}`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.extensions\.\<name>\.loaded

Whether to automatically load this extension on Burp startup\.
Unloaded extensions will still be present, but have to be manually loaded\.

_Type:_
boolean

_Default:_
`true`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.extensions\.\<name>\.priority

Priority of this module\.
Modules are loaded in order of ascending priority,
so the lowest priority is loaded first\.

_Type:_
signed integer

_Default:_
If using the list shorthand: 1000 · 1-based list index\.
Otherwise, priorities must be set manually\.

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.proEdition

Whether to enable the Pro edition\.

_Type:_
boolean

_Default:_
`false`

_Example:_
`true`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.settings

Overrides for Burp config\.json (deep merged)\.
Options added here are always wrapped in `user_options`\.

_Type:_
JSON value

_Default:_
`{ }`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)

## programs\.burp\.wordlists

Mapping of wordlist names to paths\.
These paths will be mounted at /lists/\<name> in the Burp sandbox\.

_Type:_
attribute set of absolute path

_Default:_
`{ }`

_Declared by:_

- [modules/burp\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp.nix)
