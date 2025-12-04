{
  description = "Grimstride.org web site";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (nixpkgs.legacyPackages.${system}) callPackage;
      in
      {
        packages = {
          default = callPackage ./package.nix { };
        };
      }
    );
}
