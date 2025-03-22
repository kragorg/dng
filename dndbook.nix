{
  fetchFromGitHub,
  stdenvNoCC,
  writeShellScript,
}:
let
  pname = "dndbook";
  version = "0.8.0";
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  outputs = [ "tex" ];

  phases = [
    "unpackPhase"
    "installPhase"
  ];
  src = fetchFromGitHub {
    owner = "rpgtex";
    repo = "DND-5e-LaTeX-Template";
    tag = "v${version}";
    hash = "sha256-jSYC0iduKGoUaYI1jrH0cakC45AMug9UodERqsvwVxw=";
  };
  installPhase = ''
    runHook preInstall
    dst="$tex/tex/latex/dndbook"
    mkdir -p "$dst/"
    cp -v -r * "$dst/"
    runHook postInstall
  '';
  nativeBuildInputs = [
    # multiple-outputs.sh fails if $out is not defined
    (writeShellScript "force-tex-output.sh" ''
      out="''${tex-}"
    '')
  ];
}
