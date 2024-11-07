{ system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
}:

let
  flake = (import ./flake.nix).outputs {
    self = flake;
    nixpkgs = pkgs;
    flake-utils = (import ./flake-utils.nix);
  };
in
{
  inherit (flake.packages.${system})
    godot4_4_dev3
    godot4_4_dev3_mono;
}
