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
        pkgs = nixpkgs.legacyPackages.${system};
        dungeons-and-gardens = pkgs.callPackage ./package.nix { };
      in
      rec {
        packages = {
          inherit dungeons-and-gardens;
          default = dungeons-and-gardens;
        };
        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              nixfmt-rfc-style
              pandoc
              rclone
              texliveFull
            ];
          };
        };
      }
    );
}
