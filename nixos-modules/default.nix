{ lib, config, ... }:
let
  cfg = config.functorOS.apple-silicon;
in
{
  options.functorOS.apple-silicon = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable this to set sane defaults for Apple Silicon. Most users
        will only need to set this option as well as
        `functorOS.apple-silicon.peripheralFirmwareDirectory` as the
        defaults are highly optimized.
      '';
    };
    peripheralFirmwareDirectory = lib.mkOption {
      type = lib.types.path;
      default = null;
      description = ''
        Path to peripheral firmware directory. Due to Apple copyright
        constraints, we cannot rehost these files. A typical installation of
        NixOS on Apple Silicon should leave you with a firmware directory that
        you can pass here.
      '';
    };
    modprobeHidOptions.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = ''
        Whether to set modprobe options to explicitly set the keyboard layout.
      '';
    };
    notch.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = ''
        Whether to enable the notch. This will cause the display to be treated
        as a 16:10 display where the notch covers content instead of the
        default 16:9 display behavior where the screen horizontally along the
        notch is blacked out.
      '';
    };
    notch.customizations = lib.mkOption {
      type = lib.types.bool;
      default = cfg.notch.enable;
      description = ''
        Whether to use recommended options in the functorOS Hyprland rice to optimize
        screen real estate around the notch.
      '';
    };
    bootloader.recommendedOptions = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = ''
        Whether to set recommended options in the bootloader that are essential for
        correct operation.
      '';
    };
    binaryCache.enable =
      lib.mkRemovedOptionModule [ "functorOS" "apple-silicon" "binaryCache" "enable" ]
        ''
          nixos-apple-silicon binary cache has been removed upstream. this option is deprecated.
        '';
    battery.limit.start = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 1 100);
      default = null;
      description = ''
        An integer between 1-100, which represents the battery percentage when
        the battery should begin charging.
      '';
    };
    battery.limit.end = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 1 100);
      default = null;
      description = ''
        An integer between 1-100, which represents the battery percentage when
        the battery should stop charging.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.asahi = {
      enable = true;
      peripheralFirmwareDirectory = cfg.peripheralFirmwareDirectory;
    };

    nixpkgs.overlays = [
      (final: prev: {
        aquamarine = prev.aquamarine.overrideAttrs {
          src = prev.fetchFromGitHub {
            owner = "hyprwm";
            repo = "aquamarine";
            rev = "ab2b0af63fbc9fb779d684f19149b790978be8a8";
            hash = "sha256-TclWRW2SdFeETLaiTG4BA8C8C4m/LppQEldncqyTzAQ=";
          };
        };
      })
    ];

    boot.loader.efi.canTouchEfiVariables = lib.mkIf cfg.bootloader.recommendedOptions false;

    boot.kernelParams = lib.mkIf cfg.notch.enable [ "appledrm.show_notch=1" ];

    # Keep the kernel tools' private type headers compatible with newer arm64
    # system headers, which use __u128 in ptrace and signal contexts.
    boot.kernelPatches = [
      {
        name = "tools-int128-types";
        patch = ./kernel-tools-int128.patch;
      }
    ];

    boot.extraModprobeConfig = lib.mkIf cfg.modprobeHidOptions.enable ''
      options hid_apple iso_layout=0
    '';

    services.udev.extraRules =
      lib.mkIf ((cfg.battery.limit.start != null) || cfg.battery.limit.end != null)
        (
          if (cfg.battery.limit.end == null) then
            ''
              KERNEL=="macsmc-battery", SUBSYSTEM=="power_supply", ATTR{charge_control_start_threshold}="${toString cfg.battery.limit.start}"
            ''
          else if (cfg.battery.limit.start == null) then
            ''
              KERNEL=="macsmc-battery", SUBSYSTEM=="power_supply", ATTR{charge_control_end_threshold}="${toString cfg.battery.limit.end}""
            ''
          else
            ''
              KERNEL=="macsmc-battery", SUBSYSTEM=="power_supply", ATTR{charge_control_end_threshold}="${toString cfg.battery.limit.end}", ATTR{charge_control_start_threshold}="${toString cfg.battery.limit.start}"
            ''
        );
  };
}
