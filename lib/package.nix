{
  coreutils,
  dndtex,
  fetchFromGitHub,
  gawk,
  glibcLocales,
  gnused,
  lib,
  jq,
  pandoc,
  pkgs,
  qpdf,
  src,
  stdenv,
  zsh,
}:
let
  pname = "dungeons-and-gardens";
  version = "2.0";
  scripts =
    pkgs.runCommand "dng-scripts"
      {
        nativeBuildInputs = [ gawk zsh ];
      }
      ''
        mkdir -p $out/bin
        for file in build indexhtml tohtml tolatex run chapters; do
          install -m 0755 ${src}/lib/$file $out/bin/
          patchShebangs $out/bin/$file
        done
      '';
  sort = l: lib.sort (a: b: a < b) l;
  listFiles =
    dir: map (f: "${dir}/${f}") (sort (builtins.attrNames (builtins.readDir "${src}/${dir}")));
  listMarkdown =
    dir: builtins.filter (filename: builtins.match ".*\\.md$" filename != null) (listFiles dir);
  chapters = listMarkdown "chapters";
  appendices = listMarkdown "appendices";
  characters = listMarkdown "characters";
  markdown = lib.escapeShellArgs (chapters ++ appendices ++ characters);
in
stdenv.mkDerivation rec {
  inherit pname version;
  inherit src scripts markdown;

  includetex = pkgs.writeText "include.tex" ''
    \usepackage[english]{babel}
    \usepackage[utf8]{inputenc}
    \usepackage{dblfloatfix}
    \usepackage{etoolbox}
    \newfontfamily\gillius{GilliusADFNo2}[NFSSFamily=GilliusADFNoTwo-LF]
    \sloppy
    \graphicspath{{${src}/chapters/}}
    \newcounter{dngchapter}
    \makeatletter
    \pretocmd{\@chapter}{%
      \typeout{dngchapter: \arabic{dngchapter} \thepage\space#1}%
      \stepcounter{dngchapter}
    }{}
    \makeatother
    \AtEndDocument{%
      \typeout{dngchapter: \arabic{dngchapter} \the\numexpr\value{page}+1\relax}%
    }
  '';
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    export LC_ALL="en_US.UTF-8"
    build
    runHook postBuild
  '';
  nativeBuildInputs = [
    coreutils
    dndtex
    gawk
    glibcLocales
    gnused
    jq
    pandoc
    qpdf
    scripts
    zsh
  ];

  meta = with lib; {
    description = "convert notes to PDF";
    platforms = platforms.all;
  };
}
