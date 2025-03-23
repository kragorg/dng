#! /usr/bin/env zsh
setopt errexit pipefail
: ${src:=${PWD}} ${out:=outputs/out}
: ${background:=full}

# Dependencies.
path[1,0]=( ${tex}/bin ${pandoc}/bin ${coreutils}/bin )

# We need a writable home directory for luaotfload’s font cache.
export HOME="$PWD"

# Base names for our output files. Additional names will be derived
# from these.
outtex='campaign.tex'
outpdf='Dungeons & Gardens.pdf'

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
pandoc_json=(
  ${cmd}
  --to=json
  --output=${outtex:r}.json
  ${inputs}
)
pandoc_latex=(
  ${cmd}
  --to=latex
  -V documentclass=dndbook
  -V classoption="12pt,twoside,twocolumn,openany,nodeprecatedcode"
  -V classoption="bg=${background}"
  --lua-filter=${src}/dnd.lua
  --output=${outtex}
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
  --jobname=${outpdf:r}
  ${outtex}
)
booklet=(
  pdfjam
  --quiet
  --latex =lualatex
  --paper letter
  --landscape
  --longedge
  --booklet true
  --outfile
  "${outpdf:r} (Booklet).pdf"
  ${outpdf}
)
install=(
  install
  -D -t ${out}
  -m 0644
  ${src}/index.html
  ${outtex}
  ${outtex:r}.json
  ${outpdf}
  "${outpdf:r} (Booklet).pdf"
)

function run {
  # P: Evaluate parameter name further.
  # @: Expand into separate words within quotes.
  print -u2
  print -Pru2 -- "%F{cyan}${(@Pq)${argv[1]}}%f"
  ${(@P)${argv[1]}} || {
    print -Pru2 -- "%F{red}${argv[1]} failed with exit status ${rc::=$?}%f"
    return ${rc}
  }
  print -Pru2 -- '%F{green}'$'\u2714'" ${argv[1]}%f"
}

print -Pru2 -- "%F{magenta}Building ${outpdf:r}%f"
run pandoc_json
run pandoc_latex
run fonts

# Re-run to resolve cross-references, at most five times
prev='unset'
repeat 5 {
  run latex || {
    rc=$?
    cat ${outpdf:r}.log
    exit ${rc}
  }
  [[ ${cur::="$(cksum ${outtex:r}.aux 2>&- || true)"} == ${prev} ]] && break
  prev=${cur}
}

run booklet
run install
