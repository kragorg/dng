{
  coreutils,
  dndtex,
  fetchFromGitHub,
  glibcLocales,
  lib,
  pandoc,
  pkgs,
  stdenv,
  zsh,
  background ? null,
}:
let
  pname = "dungeons-and-gardens";
  version = "1.2";
  build.zsh = ./build.zsh;
in
stdenv.mkDerivation rec {
  inherit pname version;
  inherit background coreutils pandoc;

  tex = dndtex;

  src = ./.;
  markdown = lib.escapeShellArgs (
    builtins.filter (filename: builtins.match ".*\\.md$" filename != null) (
      builtins.attrNames (builtins.readDir ./.)
    )
  );

  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    export LC_ALL="en_US.UTF-8"
    ${zsh}/bin/zsh ${build.zsh}
    runHook postBuild
  '';
  nativeBuildInputs = [
    coreutils
    dndtex
    glibcLocales
    pandoc
    zsh
  ];

  meta = with lib; {
    description = "convert notes to PDF";
    platforms = platforms.all;
  };
}
