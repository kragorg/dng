#! /bin/zsh

setopt errexit pipefail
: ${css:?} ${filename:?} ${out:?} ${title:?}

(( ${#argv} == 1 )) || exit 2

mkdir -p ${out}

function run {
    # q: Quote arguments.
    # @: Expand into separate words.
    print -Pru2 -- "%F{cyan}${(q-@)argv}%f"
    ${argv} || {
	print -Pru2 -- "%F{red}${argv[1]} failed with exit status ${rc::=$?}%f"
	return ${rc}
    }
    print -Pru2 -- '%F{green}'$'\u2714'" ${argv[1]}%f"$'\n'
}
site=( ${site} )
include=( ${include} )

cmd=(
    pandoc
    --css=${css}
    --from=markdown
    --include-before-body=${^include}
    --metadata pagetitle=${title}
    --output=${out}/${filename}
    --standalone
    --title-prefix=${^site}
    --to=html
)
run ${cmd} ${1}
