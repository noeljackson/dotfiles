#!/bin/zsh
# set -e
# set -o pipefail

# install.sh
# This script installs my basic setup for a macOS laptop

# Choose a user account to use for this installation
get_user() {
    if [ -z "${TARGET_USER}" ]; then
        # TODO: fix mapfile on macos
        #mapfile -t options < <(find /Users/* -maxdepth 0 -printf "%f\\n" -type d)

        # # if there is only one option just use that user
        # if [ "${#options[@]}" -eq "1" ]; then
        # 	readonly TARGET_USER="${options[0]}"
        # 	echo "Using user account: ${TARGET_USER}"
        # 	return
        # fi

        # # # iterate through the user options and print them
        # PS3='command -v user account should be used? '

        # select opt in "${options[@]}"; do
        # 	readonly TARGET_USER=$opt
        # 	break
        # done

        declare -rx TARGET_USER=noel
        echo "Set TARGET_USER to $TARGET_USER"

    fi

}

check_is_sudo() {
    # if [ "$EUID" -ne 0 ]; then
    # 	echo "Please run as root."
    # 	exit
    # fi
}

setup_sources() {
    brew update
    brew upgrade
    brew doctor
}



# installs base packages
# the utter bare minimal shit
base() {

    setup_sudo

    brew install \
    git \
    wget \
    curl;

    echo "Install autocompletion..."
    brew install --force zsh-completion && \
    sudo chown -R $(whoami) $(brew --prefix)/share/ && \
    sudo chown -R $(whoami):admin $(brew --prefix)/share/zsh && \
    sudo chmod -R 755 $(brew --prefix)/share/zsh && \
    sudo chmod -R 755 $(brew --prefix)/share
    autoload -Uz compinit
    rm -f ~/.zcompdump; compinit;

    echo "Install starship and fonts..."
    brew tap homebrew/cask-fonts
    brew install --cask font-hack-nerd-font
    brew install starship
    brew cleanup
    brew doctor

}

install_yubikey() {
    typeset pkgs=(
        gnupg
        hopenpgp-tools
        pinentry-mac
        ykman
        yubikey-personalization
    )
    for pkg in $pkgs
    do (
            brew install $pkg
        )
    done
}

install_devtools() {
    brew update
    install_yubikey

    typeset casks=(
        leapp
        ngrok
        orbstack
        session-manager-plugin
        visual-studio-code
    )

    for cask in $casks
    do (
            brew install --cask $cask
        )
    done

    typeset brews=(
        awscli
        dopplerhq/cli/doppler
        fnm
        git-lfs
        jq
        # node
        pyenv
    )

    for b in $brews
    do (
            brew install $b
        )
    done

    # setup fnm
    which fnm > /dev/null 2>&1 && fnm install --lts && which node > /dev/null 2>&1 && sudo ln -sf $(which node) /usr/local/bin/node

}

install_apps() {
    brew update

    brew install clamav && \
    make clamav && \
    freshclam

    typeset caskapps=(
        1password
        1password-cli
        backblaze
        discord
        exodus
        keybase
        ledger-live
        nordvpn
        raycast
        rectangle
        telegram
        tor-browser
        transmission
        vlc
        yubico-yubikey-manager
    )
    for cask in $caskapps
    do (
            brew install --quiet --cask $cask
        )
    done

    # install keyboard tools
    brew install --cask qmk-toolbox

}

# setup sudo for a user
# because fuck typing that shit all the time
# just have a decent password
# and lock your computer when you aren't using it
# if they have your password they can sudo anyways
# so its pointless
# i know what the fuck im doing ;)
setup_sudo() {
    echo "Setup Sudo for $TARGET_USER"
    sudo touch /private/etc/sudoers.d/01_${TARGET_USER}
    sudo sh -c "echo '${TARGET_USER} ALL=(ALL) NOPASSWD:ALL' >> /private/etc/sudoers.d/01_${TARGET_USER}"
    # TODO: setup downloads folder as tmpfs
}

# install rust
install_rust() {
    brew install rustup
    rustup-init -y
    rustup component add rustfmt
    source $HOME/.cargo/env
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

    )
}


install_tools() {
    # echo "Installing golang..."
    # echo
    # install_golang;

    echo
    echo "Installing rust..."
    echo
    install_rust;

    echo
    echo "Installing dev tools..."
    echo
    install_devtools
}


usage() {
    echo -e "install.sh\\n\\tThis script installs my basic setup for a debian laptop\\n"
    echo "Usage:"
    echo "  all                               	- all"
    echo "  base                                - setup sources & install base pkgs"
    echo "  tools                               - install golang, rust, and scripts"
    echo "  apps                               	- desktop apps"
    echo "  dotfiles                            - get dotfiles"
    # echo "  golang                              - install golang and packages"
    echo "  rust                                - install rust"
}

main() {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    fi


    if [[ $cmd == "all" ]]; then
        check_is_sudo
        get_user

        setup_sources

        base
        install_tools
        install_apps
        elif [[ $cmd == "base" ]]; then
        check_is_sudo
        get_user

        setup_sources

        base
        elif [[ $cmd == "tools" ]]; then
        check_is_sudo

        install_tools "$2"
        elif [[ $cmd == "yubikey" ]]; then
        check_is_sudo

        install_yubikey
        elif [[ $cmd == "apps" ]]; then
        check_is_sudo
        get_user

        setup_sources

        install_apps
        elif [[ $cmd == "dotfiles" ]]; then
        get_user
        get_dotfiles
        elif [[ $cmd == "rust" ]]; then
        install_rust
        elif [[ $cmd == "golang" ]]; then
        install_golang
    else
        usage
    fi
}

main "$@"
