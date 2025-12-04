{
  description = "Grimstride.org web site";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus/master";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils-plus,
    }:
    flake-utils-plus.lib.eachDefaultSystem (
      system:
      let
        inherit (nixpkgs.legacyPackages.${system}) callPackage;
        website = callPackage ./package.nix {};
      in
      rec {
        packages = {
          default = website;
        };
        #devShells = {
        #  default = devShell;
        #};
      }
    );
}
