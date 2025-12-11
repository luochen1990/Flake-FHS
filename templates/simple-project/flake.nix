{
  description = "Simple project using Flake FHS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fhs.url = "github:luochen1990/flake-fhs";
  };

  outputs = { nixpkgs, fhs, ... }:
    fhs.mkFlake {
      root = [ ./. ];
      nixpkgsConfig = {
        allowUnfree = true;
      };
    };
}