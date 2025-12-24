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
    binaryCache.enable = lib.mkEnableOption "enable the nixos-apple-silicon binary cache and trust its signing keys.";
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

    boot.loader.efi.canTouchEfiVariables = lib.mkIf cfg.bootloader.recommendedOptions false;

    boot.kernelParams = lib.mkIf cfg.notch.enable [ "apple_dcp.show_notch=1" ];

    boot.extraModprobeConfig = lib.mkIf cfg.modprobeHidOptions.enable ''
      options hid_apple iso_layout=0
    '';

    services.udev.extraRules =
      lib.mkIf ((cfg.battery.limit.start != null) || cfg.battery.limit.end != null)
        (
          if (cfg.battery.limit.end == null) then
            ''
              KERNEL=="macsmc-battery", SUBSYSTEM=="power_supply", ATTR{charge_control_start_threshold}="${builtins.toString cfg.battery.limit.start}"
            ''
          else if (cfg.battery.limit.start == null) then
            ''
              KERNEL=="macsmc-battery", SUBSYSTEM=="power_supply", ATTR{charge_control_end_threshold}="${builtins.toString cfg.battery.limit.end}""
            ''
          else
            ''
              KERNEL=="macsmc-battery", SUBSYSTEM=="power_supply", ATTR{charge_control_end_threshold}="${builtins.toString cfg.battery.limit.end}", ATTR{charge_control_start_threshold}="${builtins.toString cfg.battery.limit.start}"
            ''
        );

    nix.settings = lib.mkIf cfg.binaryCache.enable {
      substituters = [ "https://nixos-apple-silicon.cachix.org" ];
      trusted-public-keys = [
        "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      ];
    };
  };
}
