{
  inputs.nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon/main";

  outputs =
    { nixos-apple-silicon, self }:
    {
      nixosModules = {
        default = self.nixosModules.functoros-apple-silicon;
        functoros-apple-silicon =
          { lib, config, ... }:
          {
            imports = [
              nixos-apple-silicon.nixosModules.default
              ./nixos-modules
            ];

            nixpkgs.overlays = lib.mkIf config.functorOS.apple-silicon.enable [
              nixos-apple-silicon.overlays.apple-silicon-overlay
            ];
          };
      };

      homeManagerModules = {
        default = self.homeManagerModules.functoros-apple-silicon;
        functoros-apple-silicon = {
          imports = [ ./hm-modules ];
        };
      };
    };
}
