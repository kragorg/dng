{
  pkgs,
}:
let
  pname = "grimstride-website";
  version = "2";
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
    rec {
      source = ./dragons.md;
      title = uiop.readTitle source;
      name = "dragons";
    }
    dng-pages
  ];
}
