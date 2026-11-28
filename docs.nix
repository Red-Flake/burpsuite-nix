{
  gawk,
  gnused,
  home-manager,
  lib,
  nixosOptionsDoc,
  pkgs,
  runCommand,
  self,
}:
let
  webUrl = "https://github.com/Red-Flake/burpsuite-nix/blob/master";

  eval = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      {
        config = {
          home = {
            homeDirectory = "/home/alice";
            stateVersion = "26.05";
            username = "alice";
          };
        };
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
          d: if lib.readFileType d == "directory" then d + "/default.nix" else d
        ) opt.declarations;
      }
    else
      opt;

  docs =
    (nixosOptionsDoc {
      options = {
        programs.burp = eval.options.programs.burp;
      };
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
