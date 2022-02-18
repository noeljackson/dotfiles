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
	# for aws_completer
	autoload bashcompinit && bashcompinit
    autoload -Uz compinit
    compinit
	complete -C '$(brew --prefix)/bin/aws_completer' aws
fi

# source aliases, exports, path
for file in ~/.{aliases,path,exports}; do
	if [[ -r "$file" ]] && [[ -f "$file" ]]; then
		# shellcheck source=/dev/null
		source "$file"
	fi
done
unset file

unsetopt BEEP

bindkey "[D" backward-word
bindkey "[C" forward-word
bindkey "^[a" beginning-of-line
bindkey "^[e" end-of-line