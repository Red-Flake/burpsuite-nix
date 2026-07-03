{ pkgs, ... }:

{
  nodes.client = {
    imports = [
      "${pkgs.path}/nixos/tests/common/x11.nix"
    ];

    users.users.alice = {
      isNormalUser = true;
      home = "/home/alice";
    };

    home-manager.users.root = {
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
    client.wait_for_x()

    client.execute("nohup burpsuite >/dev/null 2>&1 &")

    # Wait for the Burp Suite process to start
    client.wait_for_window("Temporary Project")
    client.sleep(1)

    # Check if the Extension is installed and loaded
    for _ in range(13):
      client.send_key("ctrl-tab")
      client.sleep(1)
    client.wait_for_text("Burp extensions")
    client.wait_for_text("Param Miner")
  '';
}
