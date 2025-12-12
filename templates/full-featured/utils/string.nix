{ lib }:

{
  # String manipulation utilities

  # Convert string to title case
  toTitle = str:
    let
      words = lib.splitString " " str;
      capitalize = word:
        let
          first = lib.substring 0 1 word;
          rest = lib.substring 1 (-1) word;
        in
        lib.toUpper first + rest;
    in
    lib.concatStringsSep " " (map capitalize words);

  # Check if string is empty or only whitespace
  isEmpty = str:
    lib.stringLength (lib.trim str) == 0;

  # Generate random string of given length
  randomString = length:
    let
      chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
      charsList = lib.stringToCharacters chars;
      randomChar = i: lib.elemAt charsList (lib.mod (builtins.currentTime + i) (lib.length charsList));
    in
    lib.concatStrings (map randomChar (lib.range 0 (length - 1)));
}