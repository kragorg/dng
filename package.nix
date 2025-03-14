{
  lib,
  stdenv,
  pkgs,
  fetchFromGitHub,
  pandoc,
  texlive,
  zsh,
}:
let
  pname = "dungeons-and-gardens";
  version = "1.1";
  build.zsh = ./build.zsh;
  tex = pkgs.texlive.combine {
    inherit (pkgs.texlive)
      scheme-small
      bookman
      cfr-initials
      contour
      enumitem
      fontaxes
      gensymb
      gillius
      hang
      initials
      kpfonts
      kpfonts-otf
      lettrine
      luacolor
      lualatex-math
      multitoc
      numprint
      pdfcol
      pdfjam
      selnolig
      tcolorbox
      tikzfill
      titlesec
      tocloft
      ;
  };
in
stdenv.mkDerivation rec {
  inherit pname version;
  inherit pandoc tex;

  dndTemplate = fetchFromGitHub {
    owner = "rpgtex";
    repo = "DND-5e-LaTeX-Template";
    tag = "v0.8.0";
    hash = "sha256-jSYC0iduKGoUaYI1jrH0cakC45AMug9UodERqsvwVxw=";
  };

  include = pkgs.writeText "include.tex" ''
    %% Build using the D&D template: ${dndTemplate}
    \usepackage[english]{babel}
    \usepackage[utf8]{inputenc}
    \newfontfamily\gillius{GilliusADFNo2}[NFSSFamily=GilliusADFNoTwo-LF]
    \geometry{footskip=40pt}
    \sloppy
  '';

  src = ./.;
  markdown = lib.escapeShellArgs (
    builtins.filter (filename: builtins.match ".*\\.md$" filename != null) (
      builtins.attrNames (builtins.readDir ./.)
    )
  );

  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    ${zsh}/bin/zsh ${build.zsh}
    runHook postBuild
  '';
  nativeBuildInputs = [
    pandoc
    tex
    zsh
  ];

  meta = with lib; {
    description = "convert notes to PDF";
    platforms = platforms.all;
  };
}
