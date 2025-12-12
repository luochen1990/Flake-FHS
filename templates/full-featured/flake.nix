{
  description = "Full-featured project with modules and profiles using Flake FHS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-fhs.url = "github:luochen1990/flake-fhs";
  };

  outputs = { self, nixpkgs, flake-fhs, ... }:
    flake-fhs.mkFlake {
      roots = [ ./. ];
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      nixpkgsConfig = {
        allowUnfree = true;
      };
    };
}