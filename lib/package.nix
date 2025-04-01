{
  coreutils,
  dndtex,
  fetchFromGitHub,
  glibcLocales,
  gnused,
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
  markdown = lib.escapeShellArgs (
    builtins.filter (filename: builtins.match ".*\\.md$" filename != null) (
      builtins.attrNames (builtins.readDir src)
    )
  );
in
stdenv.mkDerivation rec {
  inherit pname version;
  inherit src markdown;

  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    export LC_ALL="en_US.UTF-8"
    ${zsh}/bin/zsh -df ${./build.zsh} ${markdown}
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
