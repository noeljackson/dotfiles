export PATH="/opt/homebrew/bin:$PATH"
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(starship init zsh)"
. "$HOME/.cargo/env"
eval "$(fnm env)"

