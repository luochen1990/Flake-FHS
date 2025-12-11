{
  description = "Test";

  outputs =
    { self, nixpkgs, ... }:
    let
      utilsSystem = import ./utils/utils.nix;
      level1 = utilsSystem.prepareUtils ./utils;
      level2 = level1.more { lib = nixpkgs.lib; };
      level3 = level2.more { pkgs = nixpkgs; };
      mkFlake = level3.mkFlake;
    in
    mkFlake {
      root = [ ./. ];
      inherit (self) self;
      lib = nixpkgs.lib;
      nixpkgs = nixpkgs;
      inputs = { };
    };
}
