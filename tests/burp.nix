{ ... }:

{
  nodes.client = {
    users.users.alice = {
      isNormalUser = true;
      home = "/home/alice";
    };

    home-manager.users.alice = {
      home.stateVersion = "25.05";

      programs.burp = {
        enable = true;

        extensions."param-miner".enable = true;

        cliArgs = [
          "--suppress-jre-check"
          "--i-accept-the-license-agreement"
          "--disable-auto-update"
          "--disable-check-for-updates-dialog"
          "--temporary-project"
          "--unpause-spider-and-scanner"
        ];

        preferences = {
          "use_community_edition" = "true";
        };

        settings = {
          display.user_interface = {
            # Enable Darkmode
            look_and_feel = "Dark";
            # Change Scaling
            font_size = "17";
          };
        };
      };
    };
  };

  # This test e2e verifies that the Burp Suite Configuration works correctly
  testScript = ''
    start_all()

    client.wait_for_unit("multi-user.target")
    client.wait_for_unit("home-manager-alice.service")

    client.succeed("systemctl --no-pager --full status home-manager-alice.service")
    client.wait_until_succeeds("test -e /home/alice/.BurpSuite/UserConfigCommunity.json")
    client.succeed("grep -Eq '\"look_and_feel\"[[:space:]]*:[[:space:]]*\"Dark\"' /home/alice/.BurpSuite/UserConfigCommunity.json")
    client.succeed("grep -Eq '\"font_size\"[[:space:]]*:[[:space:]]*\"17\"' /home/alice/.BurpSuite/UserConfigCommunity.json")
  '';
}
