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
  writableTmpDirAsHomeHook,
  zsh,
}:
let
  pname = "dungeons-and-gardens";
  version = "2.0";
  scripts =
    pkgs.runCommand "dng-scripts"
      {
        nativeBuildInputs = [
          gawk
          zsh
        ];
      }
      ''
        mkdir -p $out/bin
        for file in build indexhtml tohtml tolatex run chapters; do
          install -m 0755 ${src}/lib/$file $out/bin/
          patchShebangs $out/bin/$file
        done
      '';
  subdirs = [ "chapters" "appendices" "characters" ];
  sort = l: lib.sort (a: b: a < b) l;
  listFiles =
    dir:
    lib.pipe "${src}/${dir}" [
      builtins.readDir
      builtins.attrNames
      sort
      (map (f: "${dir}/${f}"))
    ];
  listMarkdown =
    dir:
    lib.pipe dir [
      listFiles
      (builtins.filter (name: builtins.match ".*\\.md$" name != null))
    ];
  markdown = lib.pipe subdirs [
    (builtins.concatMap listMarkdown)
    lib.escapeShellArgs
  ];
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
    \graphicspath{%
    ${lib.pipe subdirs [
      (map (dir: "{${src}/${dir}/}"))
      (lib.concatStringsSep "")
    ]}}
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
    writableTmpDirAsHomeHook
    zsh
  ];

  meta = with lib; {
    description = "convert notes to PDF";
    platforms = platforms.all;
  };
}
