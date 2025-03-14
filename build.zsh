#! /usr/bin/env zsh
setopt errexit pipefail
export HOME="$(mktemp -d)"
export TEXMFHOME=${HOME}/texmf
export LUA_PATH="${src}/?.lua;;"

mkdir -p ${out}
mkdir -p "$(kpsewhich -var-value TEXMFHOME)/tex/latex/"
cp -r ${dndTemplate}/* ${TEXMFHOME}/tex/latex

inputs=( ${(Q)${(z)markdown}} )
inputs=( ${(oi)inputs} )
inputs=( ${src}/${^inputs} )
intermediates=( story.json story.tex )

cmd=(
  ${pandoc}/bin/pandoc
  --standalone
  --from=markdown
  --top-level-division=chapter
  --include-in-header=${include}
)
tojson=(
  ${cmd}
  --to=json
  --output=story.json
  ${inputs}
)
tolatex=(
  ${cmd}
  --to=latex
  -V documentclass=dndbook
  -V classoption="12pt,twoside,twocolumn,openany,nodeprecatedcode"
  --lua-filter=${src}/dnd.lua
  --output=story.tex
  ${inputs}
)
topdf=(
  ${tex}/bin/lualatex
  --output-format=pdf
  story.tex
)
tobooklet=(
  ${tex}/bin/pdfjam
  --landscape
  --longedge
  --booklet true
  --outfile
  story_booklet.pdf
  story.pdf
)

for cmd ( tojson tolatex topdf tobooklet ) {
  print -Pru2 -- "%F{cyan}${(@P)cmd}%f"
  ${(@P)cmd}
}

cp -v ${src}/index.html ${out}/
cp -v ${intermediates} ${out}/
cp -v story.pdf ${out}/'Dungeons & Gardens.pdf'
cp -v story_booklet.pdf ${out}/'Dungeons & Gardens (Booklet).pdf'
