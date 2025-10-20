# GRUB bootloader configuration for NixOS
{pkgs, ...}: {
  boot = {
    bootspec.enable = true;
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        configurationLimit = 8;
      };
    };
    tmp.cleanOnBoot = true;
    kernelPackages =
      pkgs.linuxPackages_latest; # _zen, _hardened, _rt, _rt_latest, etc.

    # Silent boot
    kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "boot.shell_on_fail"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  # To avoid systemd services hanging on shutdown
  systemd.settings.Manager = { DefaultTimeoutStopSec = "10s"; };
}
