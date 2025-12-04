{
  pkgs,
  uiop,
}:
let
  inherit (pkgs.lib)
    imap0
    lists
    pipe
    strings
    ;
  title-identity = _: title: title;
  title-chapter-prefix =
    i: title: if i > 0 then "Chapter ${builtins.toString i}: ${title}" else title;
  basicNav = pkgs.writeText "header" ''
    <nav class="nav">
      <a class="home" data-tooltip="Home" href="index.html"></a>
    </nav>
  '';
  indexedNav = pkgs.writeText "header" ''
    <nav class="nav">
      <a class="up" data-tooltip="Up" href="dungeons-and-gardens.html"></a>
      <a class="home" data-tooltip="Home" href="index.html"></a>
    </nav>
  '';
  site = "Dungeons & Gardens";
  prefix = "dng-";
  collectDirectory =
    directory: title-xform:
    pipe directory [
      uiop.listMarkdown
      (imap0 (
        i: source: rec {
          inherit prefix site source;
          title = title-xform i (uiop.readTitle source);
          name = uiop.title2name title;
          include = indexedNav;
        }
      ))
    ];
  chapters = collectDirectory ./dng/chapters title-chapter-prefix;
  appendices = collectDirectory ./dng/appendices title-identity;
  characters = collectDirectory ./dng/characters title-identity;
  indexedPages = lists.flatten [
    chapters
    appendices
    characters
  ];
  index = pkgs.writeText "dungeons-and-gardens.md" (
    pipe
      [
        "# ${site}"
        ""
        "- [Synopsis](${prefix}synopsis.html)"
        ""
        "## Individual Chapters"
        ""
        (map (attrs: "- [${attrs.title}](${attrs.prefix}${attrs.name}.html)") indexedPages)
      ]
      [
        lists.flatten
        strings.concatLines
      ]
  );
in
lists.flatten [
  {
    css = "index.css";
    include = basicNav;
    name = "dungeons-and-gardens";
    source = index;
    title = "Dungeons & Gardens";
  }
  {
    inherit prefix site;
    include = indexedNav;
    name = "synopsis";
    source = ./dng/synopsis.md;
    title = "Synopsis";
  }
  indexedPages
]
