{ dndbook, texliveSmall }:
texliveSmall.withPackages (
  ps: with ps; [
    dndbook
    bookman
    cfr-initials
    contour
    dblfloatfix
    enumitem
    etoolbox
    fontaxes
    gensymb
    gillius
    hang
    initials
    kpfonts
    kpfonts-otf
    latexmk
    lettrine
    luacolor
    lualatex-math
    multitoc
    numprint
    pdfcol
    selnolig
    tcolorbox
    tikzfill
    titlesec
    tocloft
  ]
)
