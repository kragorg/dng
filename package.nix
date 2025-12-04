{
  pkgs,
}:
let
  pname = "grimstride-website";
  version = "3";
  uiop = import ./uiop.nix { inherit pkgs; };
  subsite = directory: (import directory { inherit pkgs uiop; });
  subsites = [
    ./home
    ./dng
    ./wyrmlings
  ];
in
uiop.buildSite {
  name = "${pname}-${version}";
  pages = pkgs.lib.lists.flatten (map subsite subsites);
}
