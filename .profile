# Load aliases,path, exports for bash usage and other files...
for file in ~/.{aliases,path,extra}; do
	if [[ -r "$file" ]] && [[ -f "$file" ]]; then
		# shellcheck source=/dev/null
		source "$file"
	fi
done
unset file
. "$HOME/.cargo/env"
export PATH="/Users/noel/.local/share/solana/install/active_release/bin:$PATH"
