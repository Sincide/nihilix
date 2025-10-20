# GRUB bootloader configuration for NixOS
# Supports both BIOS and UEFI boot modes
{pkgs, lib, config, ...}: let
  # Detect if system is using UEFI or BIOS
  isUefi = builtins.pathExists /sys/firmware/efi;

  # Get boot device from variables.nix if set, otherwise use "nodev" for UEFI
  bootDevice =
    if config.var ? grubDevice
    then config.var.grubDevice
    else if isUefi then "nodev"
    else "nodev"; # Let GRUB auto-detect for BIOS
in {
  boot = {
    bootspec.enable = true;
    loader = {
      efi.canTouchEfiVariables = lib.mkIf isUefi true;
      grub = {
        enable = true;
        device = bootDevice;
        efiSupport = isUefi;
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
