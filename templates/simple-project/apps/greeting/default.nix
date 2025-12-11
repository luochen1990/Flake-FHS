{ pkgs ? import <nixpkgs> {} }:

{
  type = "app";
  program = toString (pkgs.writeScriptBin "greeting-app" ''
    #!${pkgs.runtimeShell}
    echo "Hello from Flake FHS!"
    echo "This app was automatically discovered and packaged."
    echo "Current time: $(date)"
    echo "System: $(uname -a)"
  '');
}