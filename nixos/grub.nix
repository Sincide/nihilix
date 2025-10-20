# GRUB bootloader configuration for systems where systemd-boot is unavailable.
{pkgs, lib, ...}: {
  boot = {
    bootspec.enable = true;
    loader = {
      efi.canTouchEfiVariables = lib.mkDefault true;
      systemd-boot.enable = lib.mkDefault false;
      grub = {
        enable = true;
        efiSupport = true;
        useOSProber = false;
        device = "nodev";
        configurationLimit = 8;
      };
    };
    tmp.cleanOnBoot = true;
    kernelPackages = pkgs.linuxPackages_latest;
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

  systemd.settings.Manager = {DefaultTimeoutStopSec = "10s";};
}
