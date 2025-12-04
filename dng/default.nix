{
  pkgs,
  uiop,
}:
let
  inherit (pkgs.lib) flatten;
  config = {
    prefix = "dng-";
    site = "Dungeons & Gardens";
    uplink = "dungeons-and-gardens.html";
  };
  chapterPrefix = uiop.titleCondPrefix (i: "Chapter ${toString i}: ");
  chapters = uiop.mkPages chapterPrefix config ./chapters;
  appendices = uiop.mkPages uiop.titleIdentity config ./appendices;
  characters = uiop.mkPages uiop.titleIdentity config ./characters;
  indexedPages = flatten [
    chapters
    appendices
    characters
  ];
  index = pkgs.writeText (uiop.replaceExtension config.uplink "md") ''
    # ${config.site}

    - [Synopsis](${config.prefix}synopsis.html)

    ## Individual Chapters

    ${uiop.mkIndexEntries indexedPages}
  '';
in
flatten [
  {
    css = "index.css";
    name = "dungeons-and-gardens";
    source = index;
    title = "Dungeons & Gardens";
  }
  {
    inherit (config) prefix site uplink;
    name = "synopsis";
    source = ./synopsis.md;
    title = "Synopsis";
  }
  indexedPages
]
