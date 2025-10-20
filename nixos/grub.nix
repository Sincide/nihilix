# GRUB bootloader configuration for NixOS
# Supports both BIOS and UEFI boot modes
# Auto-detects boot disk for BIOS installations
{pkgs, lib, config, ...}: let
  # Detect if system is using UEFI or BIOS
  isUefi = builtins.pathExists /sys/firmware/efi;

  # For BIOS mode, try to detect the boot disk from hardware-configuration
  # Common devices: /dev/vda (VMs), /dev/sda (SATA), /dev/nvme0n1 (NVMe)
  # If detection fails, default to /dev/vda (works for VMs)
  biosBootDevice =
    if builtins.pathExists /dev/vda then "/dev/vda"
    else if builtins.pathExists /dev/sda then "/dev/sda"
    else if builtins.pathExists /dev/nvme0n1 then "/dev/nvme0n1"
    else "/dev/sda"; # fallback
in {
  boot = {
    bootspec.enable = true;
    loader = {
      efi.canTouchEfiVariables = lib.mkIf isUefi true;
      grub = {
        enable = true;
        # For UEFI: device = "nodev", for BIOS: auto-detect boot disk
        device = if isUefi then "nodev" else biosBootDevice;
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
