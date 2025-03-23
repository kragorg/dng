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
        dndbook = pkgs.callPackage ./dndbook.nix { };
        dndtex = pkgs.callPackage ./dndtex.nix { inherit dndbook; };
        dungeons-and-gardens = pkgs.callPackage ./package.nix { inherit dndtex; };
        dungeons-and-gardens-print = pkgs.callPackage ./package.nix {
          inherit dndtex;
          background = "print";
        };
      in
      rec {
        packages = {
          inherit dndbook dndtex dungeons-and-gardens;
          default = dungeons-and-gardens;
          print = dungeons-and-gardens-print;
        };
        devShells = {
          default = pkgs.mkShell {
            name = "dungeons-and-gardens-shell";
            shellHook = ''
              export src="$PWD";
              export markdown="${dungeons-and-gardens.markdown}";
            '';
            packages = with pkgs; [
              nixfmt-rfc-style
              pandoc
              rclone
              dndbook
              dndtex
            ];
          };
        };
      }
    );
}
