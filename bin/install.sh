#!/bin/zsh
set -e
set -o pipefail

# install.sh
# This script installs my basic setup for a macOS laptop

# Choose a user account to use for this installation
get_user() {
	if [ -z "${TARGET_USER-}" ]; then
	# TODO: fix mapfile on macos
		mapfile -t options < <(find /home/* -maxdepth 0 -printf "%f\\n" -type d)

		# if there is only one option just use that user
		if [ "${#options[@]}" -eq "1" ]; then
			readonly TARGET_USER="${options[0]}"
			echo "Using user account: ${TARGET_USER}"
			return
		fi

		# iterate through the user options and print them
		PS3='command -v user account should be used? '

		select opt in "${options[@]}"; do
			readonly TARGET_USER=$opt
			break
		done
		fi
	}

check_is_sudo() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root."
		exit
	fi
}


setup_sources_min() {
    brew update
	# apt update || true
	# apt install -y \
	# 	apt-transport-https \
	# 	ca-certificates \
	# 	curl \
	# 	dirmngr \
	# 	git \
	# 	gnupg2 \
	# 	lsb-release \
	# 	--no-install-recommends
}

setup_sources() {
	setup_sources_min;
}

base_min() {
	brew update
    brew upgrade
    brew doctor

	# install_scripts
}

# installs base packages
# the utter bare minimal shit
base() {
	base_min;

    brew update
    brew upgrade

    brew install zsh-completion && chmod -R go-w '/usr/local/share/zsh' && rm -f ~/.zcompdump && compinit
    brew tap homebrew/cask-fonts
    brew install --cask font-hack-nerd-font
    brew install starship
    brew cask install docker
    # brew install docker-compose
    brew cask install virtualbox
    brew cask install charles

    brew install awscli nvm node pulumi jq git-lfs

	setup_sudo

	brew doctor
}


# setup sudo for a user
# because fuck typing that shit all the time
# just have a decent password
# and lock your computer when you aren't using it
# if they have your password they can sudo anyways
# so its pointless
# i know what the fuck im doing ;)
setup_sudo() {
	# add user to sudoers
	# adduser "$TARGET_USER" sudo

	# create docker group
	# sudo groupadd docker
	# sudo gpasswd -a "$TARGET_USER" docker

	# add go path to secure path
	{ \
		# echo -e "Defaults	secure_path=\"/usr/local/go/bin:/home/${TARGET_USER}/.go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/bcc/tools:/home/${TARGET_USER}/.cargo/bin\""; \
		# echo -e 'Defaults	env_keep += "ftp_proxy http_proxy https_proxy no_proxy GOPATH EDITOR"'; \
		echo -e "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL"; \
		# echo -e "${TARGET_USER} ALL=NOPASSWD: /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery"; \

#         root ALL=(ALL) ALL
# %admin  ALL=(ALL) NOPASSWD: ALL
# %wheel ALL=(ALL) NOPASSWD: ALL
# %wheel ALL=(ALL) NOPASSWD: ALL
# %sudo   ALL=(ALL) NOPASSWD: ALL
# adamatan ALL=(ALL) NOPASSWD: ALL

	} >> /etc/sudoers

	# setup downloads folder as tmpfs
	# that way things are removed on reboot
	# i like things clean but you may not want this
	#mkdir -p "/home/$TARGET_USER/Downloads"
	#echo -e "\\n# tmpfs for downloads\\ntmpfs\\t/home/${TARGET_USER}/Downloads\\ttmpfs\\tnodev,nosuid,size=2G\\t0\\t0" >> /etc/fstab
}

# install rust
install_rust() {
	curl https://sh.rustup.rs -sSf | sh
}



# install stuff for wm
install_wmapps() {
	brew update

    echo "You must run this command on Recovery OS command + r on startup"
    echo "csrutil enable --without debug --without fs"

}

get_dotfiles() {
	# create subshell
	(
	cd "$HOME"

	if [[ ! -d "${HOME}/dotfiles" ]]; then
		# install dotfiles from repo
		git clone git@github.com:noeljackson/dotfiles.git "${HOME}/dotfiles"
	fi

	cd "${HOME}/dotfiles"

	# set the correct origin
	git remote set-url origin git@github.com:noeljackson/dotfiles.git

	# installs all the things
	make

	# enable dbus for the user session
	# systemctl --user enable dbus.socket

	# sudo systemctl enable "i3lock@${TARGET_USER}"
	# sudo systemctl enable suspend-sedation.service

	cd "$HOME"
	mkdir -p ~/Pictures/Screenshots
	)

	install_vim;
}

# install_vim() {
# 	# create subshell
# 	(
# 	cd "$HOME"

# 	# install .vim files
# 	sudo rm -rf "${HOME}/.vim"
# 	git clone --recursive git@github.com:jessfraz/.vim.git "${HOME}/.vim"
# 	(
# 	cd "${HOME}/.vim"
# 	make install
# 	)

# 	# update alternatives to vim
# 	sudo update-alternatives --install /usr/bin/vi vi "$(command -v vim)" 60
# 	sudo update-alternatives --config vi
# 	sudo update-alternatives --install /usr/bin/editor editor "$(command -v vim)" 60
# 	sudo update-alternatives --config editor
# 	)
# }

install_tools() {
	echo "Installing golang..."
	echo
	install_golang;

	echo
	echo "Installing rust..."
	echo
	install_rust;

	echo
	echo "Installing scripts..."
	echo
	sudo install.sh scripts;
}

install_music() {
	mkdir -p ~/Music/Ableton
	ln -sf /Volumes/NJMix/Ableton/* ~/Music/Ableton
}

usage() {
	echo -e "install.sh\\n\\tThis script installs my basic setup for a debian laptop\\n"
	echo "Usage:"
	echo "  base                                - setup sources & install base pkgs"
	echo "  basemin                             - setup sources & install base min pkgs"
	echo "  graphics {intel, geforce, optimus}  - install graphics drivers"
	echo "  wm                                  - install window manager/desktop pkgs"
	echo "  dotfiles                            - get dotfiles"
	echo "  vim                                 - install vim specific dotfiles"
	echo "  golang                              - install golang and packages"
	echo "  rust                                - install rust"
	echo "  scripts                             - install scripts"
	echo "  tools                               - install golang, rust, and scripts"
	echo "  dropbear                            - install and configure dropbear initramfs"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	if [[ $cmd == "base" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources

		base
	elif [[ $cmd == "basemin" ]]; then
		check_is_sudo
		get_user

		# setup /etc/apt/sources.list
		setup_sources_min

		base_min
	elif [[ $cmd == "graphics" ]]; then
		check_is_sudo

		install_graphics "$2"
	elif [[ $cmd == "wm" ]]; then
		check_is_sudo

		install_wmapps
	elif [[ $cmd == "dotfiles" ]]; then
		get_user
		get_dotfiles
	elif [[ $cmd == "vim" ]]; then
		install_vim
	elif [[ $cmd == "rust" ]]; then
		install_rust
	elif [[ $cmd == "golang" ]]; then
		install_golang "$2"
	elif [[ $cmd == "scripts" ]]; then
		install_scripts
	elif [[ $cmd == "tools" ]]; then
		install_tools
	elif [[ $cmd == "dropbear" ]]; then
		check_is_sudo

		get_user

		install_dropbear
	else
		usage
	fi
}

main "$@"
