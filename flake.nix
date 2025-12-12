{
  description = "Test";

  outputs =
    { self, nixpkgs, ... }:
    let
      utils = (((import ./utils/utils.nix).prepareUtils ./utils).more { lib = nixpkgs.lib; }).more {
        pkgs = nixpkgs;
      };
    in
    utils.mkFlake {
      roots = [ ./. ];
      inherit self nixpkgs;
      inputs = self.inputs;
    } // {
      # Provide lib and mkFlake outputs for backward compatibility with templates
      lib = utils;
      mkFlake = utils.mkFlake;
    };
}
