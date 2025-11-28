{
  gawk,
  gnused,
  lib,
  nixosOptionsDoc,
  runCommand,
  self,
}:

let
  webUrl = "https://github.com/Red-Flake/burpsuite-nix/blob/master";

  eval = lib.evalModules {
    modules = [
      {
        config._module.check = false;
        options._module.args = lib.mkOption { internal = true; };
      }
      self.homeManagerModules.default
    ];
  };

  removeTrailingNewlineInLiteralExpression =
    let
      updateAttr =
        attr: opt:
        if opt.${attr}._type or null == "literalExpression" then
          opt // { ${attr} = lib.literalExpression (lib.removeSuffix "\n" opt.${attr}.text); }
        else
          opt;
    in
    lib.flip lib.pipe [
      (updateAttr "default")
      (updateAttr "example")
    ];

  fixDeclarations =
    opt:
    if opt ? declarations then
      opt
      // {
        declarations = map (
          d: if builtins.readFileType d == "directory" then d + "/default.nix" else d
        ) opt.declarations;
      }
    else
      opt;

  docs =
    (nixosOptionsDoc {
      inherit (eval) options;
      transformOptions = lib.flip lib.pipe [
        removeTrailingNewlineInLiteralExpression
        fixDeclarations
      ];
    }).optionsCommonMark;
in

runCommand "docs" { } ''
  ${lib.getExe gnused} -E 's|\[${self}/(.*)\]\(.*\)|[\1](${webUrl}/\1)|' ${docs} \
  | ${lib.getExe gawk} '{ print ($0 == "```" && a=!a) ? "```nix" : $0 }' > $out
''
