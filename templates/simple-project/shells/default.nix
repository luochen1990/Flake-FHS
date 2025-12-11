{ pkgs ? import <nixpkgs> {} }:

{
  default = pkgs.mkShell {
    name = "flake-fhs-dev";

    buildInputs = with pkgs; [
      git
      vim
      curl
      nixfmt
      hello
    ];

    shellHook = ''
      echo "🚀 Welcome to Flake FHS development environment!"
      echo "Available commands: git, vim, curl, nixfmt, hello"
      echo "Try: nix build .#hello-custom"
    '';
  };
}