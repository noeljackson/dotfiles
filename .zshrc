#!/bin/zsh

# If not running interactively, don't do anything
case $- in
	*i*) ;;
	*) return;;
esac

# GPG & YubiKey Setup (must be early in initialization)
export GPG_TTY=$(tty)


# Ensure GPG agent is properly configured
gpgconf --launch gpg-agent 2>/dev/null || true

# Brew
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(starship init zsh)"
eval "$(fnm env --use-on-cd)"

# zsh completions
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
	# for aws_completer
	autoload bashcompinit && bashcompinit
    autoload -Uz compinit
    compinit
	complete -C '$(brew --prefix)/bin/aws_completer' aws
fi



# ngrok autocompletion
if command -v ngrok &>/dev/null; then
	eval "$(ngrok completion)"
fi

# source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
# source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"

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

# python + pyenv
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
alias pip=pip3

# conda
# shell prompt
eval "$(conda "shell.$(basename "${SHELL}")" hook)"
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# set -a
# source <(doppler secrets download --no-file --format env)
# set +a

# bun completions
[ -s "/Users/noel/.bun/_bun" ] && source "/Users/noel/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Added by Windsurf
export PATH="/Users/noel/.codeium/windsurf/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/noel/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/noel/.cache/lm-studio/bin"

# Added by Windsurf - Next
export PATH="/Users/noel/.codeium/windsurf/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
alias claude="/Users/noel/.claude/local/claude"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
