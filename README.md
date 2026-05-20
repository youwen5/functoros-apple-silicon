# functoros-apple-silicon

compatibility module for apple silicon via asahi linux

## usage

You will need to import both the NixOS module and Home Manager module for best results.

```nix
# configuration.nix
{
  imports = [
    functoros-apple-silicon.nixosModules.default
  ];
}
```

```nix
# home.nix
{
  imports = [
    functoros-apple-silicon.homeManagerModules.default
  ];
}
```

## main module options

```nix
# NixOS module options
{
  functorOS.apple-silicon = {
    # whether to enable the module and set sane defaults
    enable = true;
    # must set to path of firmware directory obtained from installation
    peripheralFirmwareDirectory = ./firmware;

    # you can set battery limits like this.
    # start is threshold when charging begins, end is when charging ends.
    # should be integers 1-100.
    battery.limit = {
      start = 80;
      end = 90;
    };

    # enable the notch
    notch.enable = true;
  };
}
```

You should read the code for the rest of the options.
