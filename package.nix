{
  pkgs,
}:
let
  pname = "grimstride-website";
  version = "1";
  uiop = import ./uiop.nix { inherit pkgs; };
  dng-pages = import ./dng.nix { inherit pkgs uiop; };
in
uiop.buildSite {
  name = "${pname}-${version}";
  pages = pkgs.lib.lists.flatten [
    {
      source = ./index.md;
      title = "Kragor Grimstride";
      name = "index";
      css = "index.css";
    }
    dng-pages
  ];
}
