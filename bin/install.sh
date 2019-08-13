#!/bin/bash
set -e
set -o pipefail

# install.sh
#	This script installs my basic setup for a debian laptop

export DEBIAN_FRONTEND=noninteractive

# Choose a user account to use for this installation
get_user() {
	if [ -z "${TARGET_USER-}" ]; then
		mapfile -t options < <(find /home/* -maxdepth 0 -printf "%f\\n" -type d)
		# if there is only one option just use that user
		if [ "${#options[@]}" -eq "1" ]; then
			readonly TARGET_USER="${options[0]}"
			echo "Using user account: ${TARGET_USER}"
			return
		fi

		# iterate through the user options and print them
		PS3='Which user account should be used? '

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
	apt update || true
	apt install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		dirmngr \
		gnupg2 \
		lsb-release \
		--no-install-recommends

	# hack for latest git (don't judge)
	cat <<-EOF > /etc/apt/sources.list.d/git-core.list
	deb http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main
	deb-src http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main
	EOF

	# neovim
	cat <<-EOF > /etc/apt/sources.list.d/neovim.list
	deb http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu xenial main
	deb-src http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu xenial main
	EOF

	# add the git-core ppa gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys E1DD270288B4E6030699E45FA1715D88E1DF1F24

	# add the neovim ppa gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 9DBB0BE9366964F134855E2255F96FCF8231B6DD

	# turn off translations, speed up apt update
	mkdir -p /etc/apt/apt.conf.d
	echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations
}

# sets up apt sources
# assumes you are going to use debian buster
setup_sources() {
	setup_sources_min;

	cat <<-EOF > /etc/apt/sources.list
	deb http://httpredir.debian.org/debian buster main contrib non-free
	deb-src http://httpredir.debian.org/debian/ buster main contrib non-free

	deb http://httpredir.debian.org/debian/ buster-updates main contrib non-free
	deb-src http://httpredir.debian.org/debian/ buster-updates main contrib non-free

	deb http://security.debian.org/ buster/updates main contrib non-free
	deb-src http://security.debian.org/ buster/updates main contrib non-free

	deb http://httpredir.debian.org/debian experimental main contrib non-free
	deb-src http://httpredir.debian.org/debian experimental main contrib non-free

	# yubico
	deb http://ppa.launchpad.net/yubico/stable/ubuntu xenial main
	deb-src http://ppa.launchpad.net/yubico/stable/ubuntu xenial main

	# tlp: Advanced Linux Power Management
	# http://linrunner.de/en/tlp/docs/tlp-linux-advanced-power-management.html
	deb http://repo.linrunner.de/debian sid main
	EOF

	# Create an environment variable for the correct distribution
	CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
	export CLOUD_SDK_REPO

	# Add the Cloud SDK distribution URI as a package source
	echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list

	# Import the Google Cloud Platform public key
	curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

	# Add the Google Chrome distribution URI as a package source
	echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

	# Import the Google Chrome public key
	curl https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

	# add the yubico ppa gpg key
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 3653E21064B19D134466702E43D5C49532CBA1A9

	# add the tlp apt-repo gpg key
	apt-key adv --keyserver pool.sks-keyservers.net --recv-keys CD4E8809
}

base_min() {
	apt update || true
	apt -y upgrade

	apt install -y \
		adduser \
		automake \
		bash-completion \
		bc \
		bzip2 \
		ca-certificates \
		coreutils \
		curl \
		dnsutils \
		file \
		findutils \
		fwupd \
		fwupdate \
		gcc \
		git \
		gnupg \
		gnupg2 \
		gnupg-agent \
		grep \
		gzip \
		hostname \
		indent \
		iptables \
		iwd \
		jq \
		less \
		libc6-dev \
		libimobiledevice6 \
		libpam-systemd \
		locales \
		lsof \
		make \
		mount \
		net-tools \
		neovim \
		pinentry-curses \
		rxvt-unicode-256color \
		scdaemon \
		ssh \
		strace \
		sudo \
		systemd \
		tar \
		tree \
		tzdata \
		usbmuxd \
		unzip \
		xclip \
		compton \
		xz-utils \
		zip \
		--no-install-recommends

	apt autoremove
	apt autoclean
	apt clean

	install_scripts
}

# installs base packages
# the utter bare minimal shit
base() {
	base_min;

	apt update || true
	apt -y upgrade

	apt install -y \
		alsa-utils \
		apparmor \
		bridge-utils \
		cgroupfs-mount \
		google-cloud-sdk \
		libapparmor-dev \
		libltdl-dev \
		libseccomp-dev \
		--no-install-recommends

	setup_sudo

	apt autoremove
	apt autoclean
	apt clean
}

# install and configure dropbear
install_dropbear() {
	apt update || true
	apt -y upgrade

	apt install -y \
		dropbear-initramfs \
		--no-install-recommends

	apt autoremove
	apt autoclean
	apt clean

	# change the default port and settings
	echo 'DROPBEAR_OPTIONS="-p 4748 -s -j -k -I 60"' >> /etc/dropbear-initramfs/config

	# update the authorized keys
	cp "/home/${TARGET_USER}/.ssh/authorized_keys" /etc/dropbear-initramfs/authorized_keys
	sed -i 's/ssh-/no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="\/bin\/cryptroot-unlock" ssh-/g' /etc/dropbear-initramfs/authorized_keys

	echo "Dropbear has been installed and configured."
	echo "You will now want to update your initramfs:"
	printf "\\tupdate-initramfs -u\\n"
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
	adduser "$TARGET_USER" sudo

	# add user to systemd groups
	# then you wont need sudo to view logs and shit
	gpasswd -a "$TARGET_USER" systemd-journal
	gpasswd -a "$TARGET_USER" systemd-network

	# create docker group
	sudo groupadd docker
	sudo gpasswd -a "$TARGET_USER" docker

	# add go path to secure path
	{ \
		echo -e "Defaults	secure_path=\"/usr/local/go/bin:/home/${USERNAME}/.go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\""; \
		echo -e 'Defaults	env_keep += "ftp_proxy http_proxy https_proxy no_proxy GOPATH EDITOR"'; \
		echo -e "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL"; \
		echo -e "${TARGET_USER} ALL=NOPASSWD: /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery"; \
	} >> /etc/sudoers

	# setup downloads folder as tmpfs
	# that way things are removed on reboot
	# i like things clean but you may not want this
	mkdir -p "/home/$TARGET_USER/Downloads"
	echo -e "\\n# tmpfs for downloads\\ntmpfs\\t/home/${TARGET_USER}/Downloads\\ttmpfs\\tnodev,nosuid,size=2G\\t0\\t0" >> /etc/fstab
}

# install rust
install_rust() {
	curl https://sh.rustup.rs -sSf | sh
}

# install/update golang from source
install_golang() {
	export GO_VERSION
	GO_VERSION=$(curl -sSL "https://golang.org/VERSION?m=text")
	export GO_SRC=/usr/local/go

	# if we are passing the version
	if [[ ! -z "$1" ]]; then
		GO_VERSION=$1
	fi

	# purge old src
	if [[ -d "$GO_SRC" ]]; then
		sudo rm -rf "$GO_SRC"
		sudo rm -rf "$GOPATH"
	fi

	GO_VERSION=${GO_VERSION#go}

	# subshell
	(
	kernel=$(uname -s | tr '[:upper:]' '[:lower:]')
	curl -sSL "https://storage.googleapis.com/golang/go${GO_VERSION}.${kernel}-amd64.tar.gz" | sudo tar -v -C /usr/local -xz
	local user="$USER"
	# rebuild stdlib for faster builds
	sudo chown -R "${user}" /usr/local/go/pkg
	CGO_ENABLED=0 go install -a -installsuffix cgo std
	)

	# get commandline tools
	(
	set -x
	set +e
	go get github.com/golang/lint/golint
	go get golang.org/x/tools/cmd/cover
	go get golang.org/x/review/git-codereview
	go get golang.org/x/tools/cmd/goimports
	go get golang.org/x/tools/cmd/gorename
	go get golang.org/x/tools/cmd/guru

	go get github.com/genuinetools/amicontained
	go get github.com/genuinetools/apk-file
	go get github.com/genuinetools/audit
	go get github.com/genuinetools/certok
	go get github.com/genuinetools/netns
	go get github.com/genuinetools/pepper
	go get github.com/genuinetools/reg
	go get github.com/genuinetools/udict
	go get github.com/genuinetools/weather

	go get github.com/jessfraz/junk/sembump
	go get github.com/jessfraz/secping
	go get github.com/jessfraz/ship
	go get github.com/jessfraz/tdash

	go get github.com/axw/gocov/gocov
	go get honnef.co/go/tools/cmd/staticcheck

	# Tools for vimgo.
	go get github.com/jstemmer/gotags
	go get github.com/nsf/gocode
	go get github.com/rogpeppe/godef

	aliases=( Azure/acs-engine genuinetools/contained.af genuinetools/binctr genuinetools/img docker/docker moby/buildkit opencontainers/runc )
	for project in "${aliases[@]}"; do
		owner=$(dirname "$project")
		repo=$(basename "$project")
		if [[ -d "${HOME}/${repo}" ]]; then
			rm -rf "${HOME:?}/${repo}"
		fi

		mkdir -p "${GOPATH}/src/github.com/${owner}"

		if [[ ! -d "${GOPATH}/src/github.com/${project}" ]]; then
			(
			# clone the repo
			cd "${GOPATH}/src/github.com/${owner}"
			git clone "https://github.com/${project}.git"
			# fix the remote path, since our gitconfig will make it git@
			cd "${GOPATH}/src/github.com/${project}"
			git remote set-url origin "https://github.com/${project}.git"
			)
		else
			echo "found ${project} already in gopath"
		fi

		# make sure we create the right git remotes
		if [[ "$owner" != "jessfraz" ]] && [[ "$owner" != "genuinetools" ]]; then
			(
			cd "${GOPATH}/src/github.com/${project}"
			git remote set-url --push origin no_push
			git remote add jessfraz "https://github.com/jessfraz/${repo}.git"
			)
		fi
	done

	# do special things for k8s GOPATH
	mkdir -p "${GOPATH}/src/k8s.io"
	kubes_repos=( community kubernetes release sig-release )
	for krepo in "${kubes_repos[@]}"; do
		git clone "https://github.com/kubernetes/${krepo}.git" "${GOPATH}/src/k8s.io/${krepo}"
		cd "${GOPATH}/src/k8s.io/${krepo}"
		git remote set-url --push origin no_push
		git remote add jessfraz "https://github.com/jessfraz/${krepo}.git"
	done
	)

	# symlink weather binary for motd
	sudo ln -snf "${GOPATH}/bin/weather" /usr/local/bin/weather
}

# install graphics drivers
install_graphics() {
	local system=$1

	if [[ -z "$system" ]]; then
		echo "You need to specify whether it's intel, geforce or optimus"
		exit 1
	fi

	local pkgs=( xorg xserver-xorg xserver-xorg-input-libinput xserver-xorg-input-synaptics )

	case $system in
		"intel")
			pkgs+=( xserver-xorg-video-intel )
			;;
		"geforce")
			pkgs+=( nvidia-driver )
			;;
		"optimus")
			pkgs+=( nvidia-kernel-dkms bumblebee-nvidia primus )
			;;
		*)
			echo "You need to specify whether it's intel, geforce or optimus"
			exit 1
			;;
	esac

	apt update || true
	apt -y upgrade

	apt install -y "${pkgs[@]}" --no-install-recommends
}

# install custom scripts/binaries
install_scripts() {
	# install speedtest
	curl -sSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py  > /usr/local/bin/speedtest
	chmod +x /usr/local/bin/speedtest

	# install icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/icdiff > /usr/local/bin/icdiff
	curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/git-icdiff > /usr/local/bin/git-icdiff
	chmod +x /usr/local/bin/icdiff
	chmod +x /usr/local/bin/git-icdiff

	# install lolcat
	curl -sSL https://raw.githubusercontent.com/tehmaze/lolcat/master/lolcat > /usr/local/bin/lolcat
	chmod +x /usr/local/bin/lolcat


	local scripts=( have light )

	for script in "${scripts[@]}"; do
		curl -sSL "https://misc.j3ss.co/binaries/$script" > "/usr/local/bin/${script}"
		chmod +x "/usr/local/bin/${script}"
	done
}

# install stuff for i3 window manager
install_wmapps() {
	local pkgs=( feh i3 i3lock i3status scrot suckless-tools )

	apt update || true
	apt install -y "${pkgs[@]}" --no-install-recommends

	# update clickpad settings
	mkdir -p /etc/X11/xorg.conf.d/
	curl -sSL https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/X11/xorg.conf.d/50-synaptics-clickpad.conf > /etc/X11/xorg.conf.d/50-synaptics-clickpad.conf

	# add xorg conf
	curl -sSL https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/X11/xorg.conf > /etc/X11/xorg.conf

	# get correct sound cards on boot
	curl -sSL https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/modprobe.d/intel.conf > /etc/modprobe.d/intel.conf

	# pretty fonts
	curl -sSL https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/fonts/local.conf > /etc/fonts/local.conf

	echo "Fonts file setup successfully now run:"
	echo "	dpkg-reconfigure fontconfig-config"
	echo "with settings: "
	echo "	Autohinter, Automatic, No."
	echo "Run: "
	echo "	dpkg-reconfigure fontconfig"
}

get_dotfiles() {
	# create subshell
	(
	cd "$HOME"

	if [[ ! -d "${HOME}/dotfiles" ]]; then
		# install dotfiles from repo
		git clone git@github.com:jessfraz/dotfiles.git "${HOME}/dotfiles"
	fi

	cd "${HOME}/dotfiles"

	# installs all the things
	make

	# enable dbus for the user session
	# systemctl --user enable dbus.socket

	sudo systemctl enable "i3lock@${TARGET_USER}"
	sudo systemctl enable suspend-sedation.service

	sudo systemctl enable systemd-networkd systemd-resolved
	sudo systemctl start systemd-networkd systemd-resolved

	cd "$HOME"
	mkdir -p ~/Pictures/Screenshots
	)

	install_vim;
}

install_vim() {
	# create subshell
	(
	cd "$HOME"

	# install .vim files
	sudo rm -rf "${HOME}/.vim"
	git clone --recursive git@github.com:jessfraz/.vim.git "${HOME}/.vim"
	(
	cd "${HOME}/.vim"
	make install
	)

	# update alternatives to neovim
	sudo update-alternatives --install /usr/bin/vi vi "$(which nvim)" 60
	sudo update-alternatives --config vi
	sudo update-alternatives --install /usr/bin/vim vim "$(which nvim)" 60
	sudo update-alternatives --config vim
	sudo update-alternatives --install /usr/bin/editor editor "$(which nvim)" 60
	sudo update-alternatives --config editor

	# install things needed for deoplete for vim
	sudo apt update || true

	sudo apt install -y \
		python3-pip \
		python3-setuptools \
		--no-install-recommends

	pip3 install -U \
		setuptools \
		wheel \
		neovim
	)
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
	elif [[ $cmd == "dropbear" ]]; then
		check_is_sudo

		get_user

		install_dropbear
	else
		usage
	fi
}

main "$@"
