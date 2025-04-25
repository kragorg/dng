{
  pkgs,
  src,
  dungeons-and-gardens,
}:
pkgs.mkShell {
  inherit src;
  inherit (dungeons-and-gardens)
    includetex
    markdown
    nativeBuildInputs
    ;
  name = "dungeons-and-gardens-shell";
  shellHook = ''
    export src="$PWD"
    export PATH=$PWD/lib:$PATH
    mkdir -p obj
    cd obj
  '';
}
