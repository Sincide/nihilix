{
  config,
  lib,
  ...
}: {
  imports = [
    # Choose your theme here:
    ../../themes/catppuccin.nix
  ];

  config.var = {
    hostname = "nihilix";
    username = "martin";
    configDirectory =
      "/home/"
      + config.var.username
      + "/.config/nixos"; # The path of the nixos configuration directory

    keyboardLayout = "se";
    consoleKeyMap = "sv-latin1";

    location = "Sweden";
    timeZone = "Europe/Stockholm";
    defaultLocale = "en_US.UTF-8";
    extraLocale = "sv_SE.UTF-8";

    git = {
      username = "martin";
      email = "martin@example.com";
    };

    autoUpgrade = false;
    autoGarbageCollector = true;
  };

  # Let this here
  options = {
    var = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };
}
