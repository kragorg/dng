{
  description = "for working on Dungeons & Gardens";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus/master";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        src = ./.;
        callPackage = nixpkgs.legacyPackages.${system}.callPackage;
        dndbook = callPackage ./lib/dndbook.nix { };
        dndtex = callPackage ./lib/dndtex.nix {
          inherit dndbook;
        };
        dungeons-and-gardens = callPackage ./lib/package.nix {
          inherit dndtex src;
        };
        dngshell = callPackage ./lib/shell.nix {
          inherit dungeons-and-gardens src;
        };
      in
      rec {
        packages = {
          inherit dndbook dndtex dungeons-and-gardens;
          default = dungeons-and-gardens;
        };
        devShells = {
          default = dngshell;
        };
      }
    );
}
