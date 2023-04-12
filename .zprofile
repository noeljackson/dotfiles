#!/bin/zsh

# Load .bashrc and other files...
for file in ~/.{zshrc,aliases,path,extra,exports}; do
	if [[ -r "$file" ]] && [[ -f "$file" ]]; then
		# shellcheck source=/dev/null
		source "$file"
	fi
done
unset file
export PATH="/Users/noel/.local/share/solana/install/active_release/bin:$PATH"
. "$HOME/.cargo/env"
