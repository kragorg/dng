{ dndbook, texliveSmall }:
texliveSmall.withPackages (
  ps: with ps; [
    dndbook
    bookman
    cfr-initials
    contour
    dblfloatfix
    enumitem
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
    pdfjam
    selnolig
    tcolorbox
    tikzfill
    titlesec
    tocloft
  ]
)
