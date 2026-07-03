{ ... }:

{
  nodes.client = {
    users.users.alice = {
      isNormalUser = true;
      home = "/home/alice";
    };

    home-manager.users.alice = {
      home.stateVersion = "25.05";

      programs.java.userPrefs = {
        "burp" = {
          "global.suite.deviceId" = "vyogc3mm6uedd3ntpi58";
        };
        "burp/extensions/_HTTP Request Smuggler" = {
          "global.suite.deviceId" = "test";
        };
      };
    };
  };

  testScript = ''
    import shlex

    start_all()

    client.wait_for_unit("multi-user.target")
    client.wait_for_unit("home-manager-alice.service")

    ###
    ### Check that the prefs.xml content is generated correctly
    ###

    client.wait_until_succeeds("test -e /home/alice/.java/.userPrefs/burp/prefs.xml")

    expected = """<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">
    <map MAP_XML_VERSION="1.0">
      <entry key="global.suite.deviceId" value="vyogc3mm6uedd3ntpi58"/>
    </map>
    """

    actual = client.succeed("cat /home/alice/.java/.userPrefs/burp/prefs.xml")
    assert actual == expected, f"Unexpected prefs.xml:\n{actual}"

    ###
    ### Check that the special path encoding works correctly
    ###

    path = """/home/alice/.java/.userPrefs/burp/extensions/_!&8!]!"`!&@!`!!g!&)!~@"x!(`!~@"z!(@!)!"^!\'0!d@"n!\'c!b!"l!()=/prefs.xml"""

    client.succeed(f"test -e {shlex.quote(path)}")

    expected = """<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">
    <map MAP_XML_VERSION="1.0">
      <entry key="global.suite.deviceId" value="test"/>
    </map>
    """

    actual = client.succeed(f"cat {shlex.quote(path)}")
    assert actual == expected, f"Unexpected prefs.xml for special path:\n{actual}"
  '';
}
