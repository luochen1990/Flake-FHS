# Chainable utils preparation system

let
  inherit (import ./dict.nix) unionFor;
  inherit (import ./file.nix) findFiles hasPostfix;
in
{
  prepareUtils =
    utilsPath:

    let
      lv1 = unionFor (findFiles (hasPostfix "nix") utilsPath) import;
      lv2 =
        args: unionFor (findFiles (hasPostfix "nix") (utilsPath + "/more")) (fname: import fname args);
      lv3 =
        args: unionFor (findFiles (hasPostfix "nix") (utilsPath + "/more/more")) (fname: import fname args);
    in
    {
      more =
        { lib }:
        {
          more = { pkgs }: lv3 { inherit lib pkgs; } // lv2 { inherit lib; } // lv1;
        }
        // lv2 { inherit lib; }
        // lv1;
    }
    // lv1;
}
