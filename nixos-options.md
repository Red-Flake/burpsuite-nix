## programs\.burp\.enable



Whether to enable Burp Suite\.



*Type:*
boolean



*Default:*

```nix
false
```nix



*Example:*

```nix
true
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.enableJruby



Whether to enable Jruby support\.



*Type:*
boolean



*Default:*

```nix
false
```nix



*Example:*

```nix
true
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.enableJython



Whether to enable Jython support\.



*Type:*
boolean



*Default:*

```nix
false
```nix



*Example:*

```nix
true
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.package



The burpsuite package to use\.



*Type:*
package



*Default:*

```nix
pkgs.burpsuite
```nix

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.cliArgs

Additional command line arguments to pass to Burp



*Type:*
list of string



*Default:*

```nix
[ ]
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.extensions



Attribute set of Burp extensions\.
Extension names like “403-bypasser” are resolved automatically from
` burpPackages.${pkgs.stdenv.hostPlatform.system} ` without needing to reference the input\.
Extension ordering can be controlled with lib\.hm\.dag\.entryBefore and lib\.hm\.dag\.entryAfter\.



*Type:*
DAG of submodule



*Default:*

```nix
{ }
```nix

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.extensions\.\<name>\.enable



Whether to enable this extension\.
Disabled extensions won’t be present in the generated config\.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.extensions\.\<name>\.package



Nix package for this extension\. Can be:

 - A package name string (resolved from burpPackages)
 - A full derivation
 - A fetchurl/fetchFromGitHub result for the JAR file directly



*Type:*
extension package or package name convertible to it



*Default:*

```nix
burpPackages.\x86_64-linux.<extension-name>
```nix

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.extensions\.\<name>\.entrypoint



Override the entrypoint for the extension (JAR file name relative to the lib directory)\.
Only needed for custom extensions that don’t have BappManifest\.bmf\.



*Type:*
string



*Default:*

```nix
""
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.extensions\.\<name>\.extensiontype



Extension type for custom extensions fetched from sources other than the BApp store\.
Values: “1” for Java, “2” for Python, “3” for Ruby\.
Required when using custom GitHub extensions\.



*Type:*
null or one of “1”, “2”, “3”



*Default:*

```nix
null
```nix

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.extensions\.\<name>\.loaded



Whether to automatically load this extension on Burp startup\.
Unloaded extensions will still be present, but have to be manually loaded\.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.extensions\.\<name>\.serialversion



Serial version for custom extensions fetched from sources other than the BApp store\.
Required when using custom GitHub extensions\.



*Type:*
string



*Default:*

```nix
"1"
```nix

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.extensions\.\<name>\.settings



Sets preferences for this extension via the Java Preferences API\.
Options added here are only applied, if the prefs file doesn’t already exist\.



*Type:*
JSON value



*Default:*

```nix
{ }
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.extensions\.\<name>\.uuid



UUID for custom extensions fetched from sources other than the BApp store\.
Required when using custom GitHub extensions\.



*Type:*
string



*Default:*

```nix
""
```nix

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.license



Burp Suite license key\.
When set, will be added to Java preferences as license1\.



*Type:*
string



*Default:*

```nix
""
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.preferences



Sets preferences set by Burpsuite via the Java Preferences API\.
Options added here are only applied, if the prefs file doesn’t already exist\.



*Type:*
JSON value



*Default:*

```nix
{ }
```nix

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.proEdition



Whether to enable the Pro edition\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```nix

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.settings



Overrides for Burp config\.json (deep merged)\.
Options added here are always wrapped in ` user_options `\.



*Type:*
JSON value



*Default:*

```nix
{ }
```

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)



## programs\.burp\.wordlists



Mapping of wordlist names to paths\.
These paths will be mounted at /lists/\<name> in the Burp sandbox\.



*Type:*
attribute set of absolute path



*Default:*

```nix
{ }
```nix

*Declared by:*
 - [modules/burp/default\.nix](https://github.com/Red-Flake/burpsuite-nix/blob/master/modules/burp/default\.nix)


