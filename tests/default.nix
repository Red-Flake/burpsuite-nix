{
  pkgs,
  self,
  home-manager,
  lib,
}:

{
  burp = pkgs.testers.runNixOSTest {
    name = "burp";
    enableOCR = true;

    imports = [
      (import ./burp.nix {
        inherit pkgs lib home-manager;
      })
    ];

    defaults = {

      imports = [
        home-manager.nixosModules.home-manager
      ];

      home-manager.useGlobalPkgs = true;

      home-manager.sharedModules = [
        self.homeManagerModules.default
      ];
    };
  };

  prefs = pkgs.testers.runNixOSTest {
    name = "prefs";

    imports = [
      ./prefs.nix
    ];

    defaults = {
      imports = [
        home-manager.nixosModules.home-manager
      ];

      home-manager.useGlobalPkgs = true;

      home-manager.sharedModules = [
        self.homeManagerModules.default
      ];
    };
  };
}
