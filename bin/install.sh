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
        android-studio
        charles
        cocoapods
        docker
        virtualbox
        visual-studio-code
    )
    
    for cask in $casks
    do (
            brew install --cask $cask
        )
    done
    
    typeset brews=(
        awscli
        fnm
        git-lfs
        jq
        lima
        mutagen-io/mutagen/mutagen
        # node
        terraform
    )
    
    for b in $brews
    do (
            brew install $b
        )
    done
    which fnm > /dev/null 2>&1 && fnm install --lts && which node > /dev/null 2>&1 && sudo ln -sf $(which node) /usr/local/bin/node

    # vs code extensions
    typeset vsextensions=(
        aaron-bond.better-comments
        shakram02.bash-beautify
        ms-azuretools.vscode-docker
        ms-vscode.vscode-typescript-tslint-plugin
        ms-vscode-remote.remote-containers
        esbenp.prettier-vscode
        visualstudioexptteam.vscodeintellicode
        prisma.prisma
        esbenp.prettier-vscode
        graphql.vscode-graphql
        dbaeumer.vscode-eslint
        christian-kohler.npm-intellisense
        eg2.vscode-npm-script
        github.vscode-pull-request-github
        angular.ng-template
        GitHub.copilot
        
    )
    for e in $vsextensions
    do (
            code --force --install-extension  $e
        )
    done
    
}

install_apps() {
    brew update

    brew install clamav && \
    make clamav && \
    freshclam
    
    typeset caskapps=(
        1password
        1password-cli
        ableton-live-suite
        adobe-creative-cloud
        authy
        backblaze
        brave-browser
        carbon-copy-cloner
        clay
        discord
        exodus
        iterm2
        keybase
        ledger-live
        nordvpn
        omnifocus
        rectangle
        rescuetime
        slack
        sketch
        spotify
        tor-browser
        vlc
    )
    for cask in $caskapps
    do (
            brew install --quiet --cask $cask
        )
    done
    # install keyboard tools
    brew tap homebrew/cask-drivers
    brew install --cask qmk-toolbox
    
    #TODO: install browser extensions programmatically
    
    typeset extensions=(
        #mymind
        nmgcefdhjpjefhgcpocffdlibknajbmj

        # phantom
        bfnaelmomeimhlpmgjnjophhpkkoljpa
        # superhuman
        dcgcnpooblobhncpnddnhoendgbnglpn


    )
    

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
    echo "Setup Sudo for $TARGET_USER"
    # add go path to secure path
    # sudo \
    # { \
    # echo -e "Defaults	secure_path=\"/usr/local/go/bin:/home/${TARGET_USER}/.go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/bcc/tools:/home/${TARGET_USER}/.cargo/bin\""; \
    # echo -e 'Defaults	env_keep += "ftp_proxy http_proxy https_proxy no_proxy GOPATH EDITOR"'; \
    
    sudo touch /private/etc/sudoers.d/01_${TARGET_USER}
    sudo sh -c "echo '${TARGET_USER} ALL=(ALL) NOPASSWD:ALL' >> /private/etc/sudoers.d/01_${TARGET_USER}"
    
    #         root ALL=(ALL) ALL
    # %admin  ALL=(ALL) NOPASSWD: ALL
    # %wheel ALL=(ALL) NOPASSWD: ALL
    # %wheel ALL=(ALL) NOPASSWD: ALL
    # %sudo   ALL=(ALL) NOPASSWD: ALL
    
    # } >> /private/etc/sudoers.d/01_${USER};
    
    # TODO: setup downloads folder as tmpfs
    
}

# install rust
install_rust() {
    brew install rustup
    rustup-init -y
    rustup component add rustfmt
    source $HOME/.cargo/env
}

install_solana() {
    #TODO: Check for rust installation
    #TODO: Build from source
    sh -c "$(curl -sSfL https://release.solana.com/v$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/solana-labs/solana/releases/latest| sed -E 's/.+\/tag\/v(.+)/\1/')/install)"
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
    
    echo
    echo "Installing solana..."
    echo
    install_solana
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
    echo "  solana                              - install solana"
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
