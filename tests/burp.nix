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
      home.stateVersion = "26.05";

      programs.burp = {
        enable = true;

        extensions."param-miner".enable = true;
        extensions."jwt-editor" = {
          enable = true;
          settings = {
            # YELLOW is not default, Orange is
            "string_com.blackberry.jwteditor.settings" =
              ''{"scanner_insertion_point_provider_enabled":false,"intruder_payload_processor_parameter_name":"q","proxy_history_highlight_color":"YELLOW","proxy_listener_enabled":true,"scanner_insertion_point_provider_parameter_name":"kid","intruder_payload_processor_resign":false,"intruder_payload_processor_fuzz_location":"PAYLOAD"}'';
          };
        };

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
    client.sleep(2)
    client.screenshot("temporary-project")

    # Check if the Extension is installed and loaded

    for _ in range(14):
      client.send_key("ctrl-tab")
      client.sleep(1)
    client.wait_for_text("Burp extensions")
    client.wait_for_text("Param Miner")
    client.screenshot("extensions-tab")

    # Check if Extension settings work

    client.send_key("ctrl-tab")
    client.send_key("ctrl-tab")
    for _ in range(17):
      client.send_key("tab")
      client.sleep(1)
    client.send_key("right")
    client.send_key("right")
    client.wait_for_text("Yellow")
    client.screenshot("extension-settings")
  '';
}
