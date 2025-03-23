#! /usr/bin/env zsh
setopt errexit pipefail
: ${src:=${PWD}} ${out:=outputs/out}

# Dependencies.
path[1,0]=( ${tex}/bin ${pandoc}/bin ${gnused}/bin ${coreutils}/bin )

# We need a writable home directory for luaotfload’s font cache.
export HOME="$PWD"

# Base names for our output files. Additional names will be derived
# from these.
texbase='campaign.tex'
pdfbase='Dungeons & Gardens.pdf'
texprint=${texbase:r}-print.tex
pdfprint="${pdfbase:r} (Print).pdf"
pdfbooklet="${pdfbase:r} (Booklet).pdf"

# `markdown` contains the names of the source files, each of which may
# be shell-quoted.
inputs=( ${(Q)${(z)markdown}} )  # z: Split into words using shell parsing. Q: Remove quoting.
inputs=( ${(i)inputs} )          # i: Sort case-insensitively.
inputs=( ${src}/${^inputs} )     # ^: RC_EXPAND_PARAM.

cmd=(
  pandoc
  --standalone
  --from=markdown
  --top-level-division=chapter
  --include-in-header=${src}/include.tex
)
pandoc_latex=(
  ${cmd}
  --to=latex
  -V documentclass=dndbook
  -V classoption="letterpaper,12pt,twoside,twocolumn,openany"
  -V classoption="nodeprecatedcode,bg=full"
  --lua-filter=${src}/dnd.lua
  --output=${texbase}
  ${inputs}
)
fonts=(
  luaotfload-tool
  --formats=otf
  --update
)
latex=(
  lualatex
  --interaction=batchmode
  --halt-on-error
  --output-format=pdf
)
booklet=(
  pdfjam
  --quiet
  --latex =lualatex
  --paper letter
  --landscape
  --longedge
  --booklet true
  --outfile ${pdfbooklet}
  ${pdfprint}
)
install=(
  install
  -D -t ${out}
  -m 0644
  ${src}/index.html
  ${texbase}
  ${pdfbase}
  ${pdfprint}
  ${pdfbooklet}
)

function run {
  # q: Quote arguments.
  # @: Expand into separate words.
  print -u2
  print -Pru2 -- "%F{cyan}${(q@)argv}%f"
  ${argv} || {
    print -Pru2 -- "%F{red}${argv[1]} failed with exit status ${rc::=$?}%f"
    return ${rc}
  }
  print -Pru2 -- '%F{green}'$'\u2714'" ${argv[1]}%f"
}

function latex {
  local cur=''
  local prev='unset'
  local rc=0
  local jobname=$1
  local input=$2

  # Re-run to resolve cross-references, at most five times
  prev='unset'
  repeat 5 {
    run ${latex} --jobname=${jobname} ${input} || {
      rc=$?
      cat ${pdfbase:r}.log
      exit ${rc}
    }
    [[ ${cur::="$(cksum ${texbase:r}.aux 2>&- || true)"} == ${prev} ]] && break
    prev=${cur}
  }
}

print -Pru2 -- "%F{magenta}Building ${pdfbase:r}%f"
run ${pandoc_latex}
run sed -E -e 's/,bg=full\]/,bg=print]/' ${texbase} > ${texprint}

run ${fonts}
latex ${pdfbase:r} ${texbase}
latex ${pdfprint:r} ${texprint}

run ${booklet}
run ${install}
