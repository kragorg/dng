{
  pkgs,
}:
let
  inherit (pkgs.lib) lists sort strings pipe;
  src = ./.;
  env = pkgs.symlinkJoin {
    name = "grimstride-buildpage-env";
    paths = [
      pkgs.coreutils
      pkgs.pandoc
      pkgs.zsh
    ];
  };
in
rec {

  readTitle =
    path:
    let
      template = builtins.toFile "title-template.txt" "$title$";
      result = pkgs.runCommand "readTitle" { } ''
        ${pkgs.pandoc}/bin/pandoc \
          --template=${template} \
          --shift-heading-level-by=-1 \
          --from=markdown \
          --to=plain \
          "${path}" > "$out"
      '';
    in
    strings.trim (builtins.readFile result);

  title2name =
    title:
    pipe title [
      strings.toLower
      strings.sanitizeDerivationName
    ];

  listFiles =
    dir:
    pipe dir [
      builtins.readDir
      builtins.attrNames
      (ls: sort (a: b: a < b) ls)
      (map (fname: "${dir}/${fname}"))
    ];

  listMarkdown =
    dir:
    pipe dir [
      listFiles
      (builtins.filter (fname: builtins.match ".*\\.md$" fname != null))
    ];

  buildPage =
    {
      css ? "main.css",
      include ? "",
      name,
      prefix ? "",
      site ? "",
      source,
      title,
    }:
    let
      prefixedName = "${prefix}${name}";
    in
    derivation {
      inherit
        css
        include
        site
        source
        title
        ;
      name = prefixedName;
      filename = "${prefixedName}.html";

      PATH = "${env}/bin";
      LC_ALL = "C.UTF-8";
      LANG = "C.UTF-8";

      args = [
        "--no_global_rcs"
        "--no_rcs"
        ./buildPage.zsh
        source
      ];
      builder = "${pkgs.zsh}/bin/zsh";
      system = pkgs.stdenv.hostPlatform.system;
    };

  buildSite =
    {
      name,
      pages ? [ ],
    }:
    let
      env = pkgs.symlinkJoin {
        name = "${name}-env";
        paths = map buildPage pages;
      };
    in
    pkgs.runCommand name { } ''
      mkdir -p $out
      cp -RH ${env}/* $out
      cd ${src}
      ${pkgs.fd}/bin/fd -e css -e jpg -e png -e woff2 -X cp {} $out
    '';

}
