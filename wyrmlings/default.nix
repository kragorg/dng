{
  pkgs,
  uiop,
}:
let
  inherit (pkgs.lib) flatten;
  config = {
    prefix = "wyr-";
    site = "Wyrmlings";
    uplink = "wyrmlings.html";
  };
  pages = uiop.mkPages uiop.titleIdentity config ./.;
  header = builtins.readFile ./index.md;
  index = pkgs.writeText (uiop.replaceExtension config.uplink "md") ''
    ${header}

    ${uiop.mkIndexEntries pages}
  '';
in
flatten [
  rec {
    name = "wyrmlings";
    source = index;
    title = uiop.readTitle source;
    css = "index.css";
  }
  pages
]
