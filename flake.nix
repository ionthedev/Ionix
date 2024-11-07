{
  description = "Ionix Nix packages";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in
      {
        packages = rec {
          godot4_4_dev3 = pkgs.callPackage ./packages/godot/godot4_4_dev3.nix {
            inherit (pkgs) speech-dispatcher;
          };
          godot4_4_dev3_mono = pkgs.callPackage ./packages/godot/godot4_4_dev3_mono.nix {
            inherit (pkgs)
              speech-dispatcher
              mono
              dotnet-sdk_8
              dotnet-runtime_8;
          };
          default = godot4_4_dev3;
        };
      }
    ) // {
      overlays.default = final: prev: let
        pkgs = import nixpkgs {
          system = prev.system;
          config.allowUnfree = true;
        };
      in {
        godot4_4_dev3 = pkgs.callPackage ./packages/godot/godot4_4_dev3.nix {
          inherit (pkgs) speech-dispatcher;
        };
        godot4_4_dev3_mono = pkgs.callPackage ./packages/godot/godot4_4_dev3_mono.nix {
          inherit (pkgs)
            speech-dispatcher
            mono
            dotnet-sdk_8
            dotnet-runtime_8;
        };
      };

      homeManagerModules.default = { config, pkgs, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
        nixpkgs.config = {
          allowUnfree = true;
        };
      };
    };
}
