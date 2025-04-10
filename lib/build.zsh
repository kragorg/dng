#! /usr/bin/env zsh -df
setopt errexit pipefail
: ${src:=${PWD}} ${out:=outputs/out}

# We need a writable home directory for luaotfload’s font cache.
export HOME="$PWD"

# Base names for our output files. Additional names will be derived
# from these.
texbase='campaign.tex'
pdfbase='Dungeons & Gardens.pdf'
texprint=${texbase:r}-print.tex
pdfprint="${pdfbase:r} (Print).pdf"
pdfbooklet="${pdfbase:r} (Booklet).pdf"

# If the source file names are given on the command line, we use that.
# Otherwise we expect them to be specified in the environment variable
# `markdown`, shell-quoted. The file names are relative to the `src`
# directory.
if (( ${#argv} > 0 )) {
  inputs=( ${argv} )
} else {
  inputs=( ${(Q)${(z)markdown}} )  # z: Split into words using shell parsing. Q: Remove quoting.
}
inputs=( ${src}/${^inputs} )       # ^: RC_EXPAND_PARAM.

cmd=(
  pandoc
  --standalone
  --from=markdown
  --top-level-division=chapter
  --include-in-header=${src}/lib/include.tex
)
pandoc_latex=(
  ${cmd}
  --to=latex
  -V documentclass=dndbook
  -V classoption="letterpaper,12pt,twoside,twocolumn,openany"
  -V classoption="nodeprecatedcode,bg=full"
  --lua-filter=${src}/lib/dnd.lua
  --output=${texbase}
  ${inputs}
)
sed_for_print=(
  sed -E -e
  's/,bg=full\b/,bg=print/'
)
fonts=(
  luaotfload-tool
  --formats=otf
  --update
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

function dolatex {
  zparseopts -K -D -a opts -A values -job:
  if (( ${#argv} != 1 )) {
    print -Pru2 -- "%F{red}Error: ${0} requires exactly one argument%f"
    exit 2
  }
  # `jobname` is an undocumented special parameter. avoid it.
  local input=${argv[1]}
  local job=${values[--job]}
  : ${job:=${input:t:r}}

  local latex=(
    lualatex
    --interaction=batchmode
    --halt-on-error
    --output-format=pdf
    --jobname=${job}
    ${input}
  )

  # Re-run to resolve cross-references et cetera, at most five times
  local cur=''
  local prev='unset'
  local rc=0
  repeat 5 {
    print -Pru2 -- "%F{cyan}${(q@)latex}%f"
    ${latex} || {
      rc=$?
      cat ${job:t:r}.log >&2
      exit ${rc}
    }
    [[ ${cur::="$(cksum ${job:t:r}.aux 2>&- || true)"} == ${prev} ]] && break
    prev=${cur}
  }
}

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

print -Pru2 -- "%F{magenta}Building ${pdfbase:r}%f"
run ${pandoc_latex}
run ${sed_for_print} ${texbase} > ${texprint}

run ${fonts}
run dolatex --job ${pdfbase:r} ${texbase}
run dolatex --job ${pdfprint:r} ${texprint}

run ${booklet}
run ${install}
