{
  coreutils,
  dndtex,
  fetchFromGitHub,
  glibcLocales,
  gnused,
  includetex,
  lib,
  pandoc,
  pkgs,
  src,
  stdenv,
  zsh,
}:
let
  pname = "dungeons-and-gardens";
  version = "1.3";
  sort = l: lib.sort (a: b: a < b) l;
  listFiles =
    dir: map (f: "${dir}/${f}") (sort (builtins.attrNames (builtins.readDir "${src}/${dir}")));
  sessions = builtins.filter (filename: builtins.match ".*\\.md$" filename != null) (listFiles "sessions");
  appendices = listFiles "appendices";
  markdown = lib.escapeShellArgs ([ "summary.md" ] ++ sessions ++ appendices);
in
stdenv.mkDerivation rec {
  inherit pname version;
  inherit src markdown;

  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    export LC_ALL="en_US.UTF-8"
    export includetex="${includetex}"
    ${zsh}/bin/zsh -df ${./build.zsh}
    runHook postBuild
  '';
  nativeBuildInputs = [
    coreutils
    dndtex
    glibcLocales
    gnused
    pandoc
    zsh
  ];

  meta = with lib; {
    description = "convert notes to PDF";
    platforms = platforms.all;
  };
}
