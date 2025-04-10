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
        pkgs = nixpkgs.legacyPackages.${system};
        dndbook = pkgs.callPackage ./lib/dndbook.nix { };
        dndtex = pkgs.callPackage ./lib/dndtex.nix { inherit dndbook; };
        dungeons-and-gardens = pkgs.callPackage ./lib/package.nix { inherit dndtex src; };
      in
      rec {
        packages = {
          inherit dndbook dndtex dungeons-and-gardens;
          default = dungeons-and-gardens;
        };
        devShells = {
          default = pkgs.mkShell {
            name = "dungeons-and-gardens-shell";
            shellHook = ''
              export src="$PWD";
              export markdown="${dungeons-and-gardens.markdown}";
            '';
            packages = dungeons-and-gardens.nativeBuildInputs ++ [
              pkgs.nixfmt-rfc-style
              pkgs.rclone
            ];
          };
        };
      }
    );
}
