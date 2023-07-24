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

# go-jira autocompletion
if command -v jira &>/dev/null; then
	eval "$(jira --completion-script-bash)"
fi


# ngrok autocompletion
if command -v ngrok &>/dev/null; then
	eval "$(ngrok completion)"
fi

source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"

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
