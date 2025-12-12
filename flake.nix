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
      inherit (self) self;
      nixpkgs = nixpkgs;
      inputs = { };
    };
}
