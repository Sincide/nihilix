# GRUB bootloader configuration for NixOS
# Supports both BIOS and UEFI boot modes
# Auto-detects boot disk for BIOS installations
{pkgs, lib, config, ...}: let
  # Detect if system is using UEFI or BIOS
  isUefi = builtins.pathExists /sys/firmware/efi;

  # For BIOS mode, detect boot device from root filesystem device
  # Extract the disk device from the root filesystem configuration
  rootDevice =
    if config.fileSystems."/".device != null
    then
      let
        device = config.fileSystems."/".device;
        # Extract base device:
        # /dev/vda1 -> /dev/vda
        # /dev/sda1 -> /dev/sda
        # /dev/nvme0n1p1 -> /dev/nvme0n1
        # Remove partition indicators (p1, p2, or just 1, 2, etc.)
        baseDevice = builtins.head (builtins.match "(/dev/[a-z0-9]+)(p?[0-9]+)?" device);
      in baseDevice
    else "/dev/sda"; # fallback

  biosBootDevice = if isUefi then "nodev" else rootDevice;
in {
  boot = {
    bootspec.enable = true;
    loader = {
      efi.canTouchEfiVariables = lib.mkIf isUefi true;
      grub = {
        enable = true;
        # For UEFI: device = "nodev", for BIOS: auto-detect boot disk from root filesystem
        device = biosBootDevice;
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
