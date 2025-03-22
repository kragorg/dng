{ dndbook, texliveSmall }:
texliveSmall.withPackages (
  ps: with ps; [
    dndbook
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
  ]
)
