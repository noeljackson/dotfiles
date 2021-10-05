#!/bin/zsh

# If not running interactively, don't do anything
case $- in
	*i*) ;;
	*) return;;
esac

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(starship init zsh)"
eval "$(fnm env)"

# zsh completions
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit
fi

# source aliases, exports, path
for file in ~/.{aliases,path,exports}; do
	if [[ -r "$file" ]] && [[ -f "$file" ]]; then
		# shellcheck source=/dev/null
		source "$file"
	fi
done
unset file