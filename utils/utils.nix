# Chainable utils preparation system

let
  inherit (import ./dict.nix) unionFor;
  inherit (import ./file.nix) findFiles hasPostfix isNonEmptyDir;
in
{
  prepareUtils =
    utilsPath:

    let
      lv1 = unionFor (findFiles (hasPostfix "nix") utilsPath) import;
      lv2 =
        args:
        if isNonEmptyDir (utilsPath + "/more") then
          unionFor (findFiles (hasPostfix "nix") (utilsPath + "/more")) (fname: import fname args)
        else
          { };
      lv3 =
        args:
        if isNonEmptyDir (utilsPath + "/more/more") then
          unionFor (findFiles (hasPostfix "nix") (utilsPath + "/more/more")) (fname: import fname args)
        else
          { };
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
