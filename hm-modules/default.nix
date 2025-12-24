tools@{ lib, config, ... }:
let
  cfg = config.functorOS.apple-silicon;
in
{
  options.functorOS.apple-silicon = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = if tools ? osConfig then tools.osConfig.functorOS.apple-silicon.enable else false;
      description = ''
        Enable this to set sane defaults for Apple Silicon. Most users
        will only need to set this option. If you are also using the
        corresponding NixOS module, it should be unnecessary to set this.
      '';
    };
    notch.customizations = lib.mkOption {
      type = lib.types.bool;
      default =
        if tools ? osConfig then tools.osConfig.functorOS.apple-silicon.notch.enable else cfg.enable;
      description = ''
        Whether to use recommended options in the functorOS Hyprland rice to optimize
        screen real estate around the notch.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    functorOS.desktop = lib.mkIf cfg.notch.customizations {
      hyprland.screenlocker.monitor = lib.mkDefault "eDP-1";
      hyprland.screenlocker.useCrashFix = true;
      waybar.variant = "compact";
    };
  };
}
