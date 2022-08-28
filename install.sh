#!/bin/bash
NEEDS=(.config)
FILES=(.zshrc .gitconfig .p10k.zsh)
DIRECTORIES=(.config/mpv .config/foot .vim)

SWAY_FILES=(.config/sway .config/waybar .config/swaylock .sway-launcher-desktop)
SWAY_DEPS=(sway swaylock swayidle pavucontrol blueberry pavucontrol swaybg swayimg waybar mako noto-fonts-emoji file-roller pamixer imagemagick jq foot grim slurp wl-clipboard ttf-material-design-icons-git greetd greetd-gtkgreet)
SWAY_SYSTEMD_SERVICES=(greetd.service)

DIRNAME="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

die() {
    echo $@;
    exit 1;
}

# choice prompt
choice() {
    echo "$@ [y/N]"
    read -n 1 ch

    if ! [ "$ch" == "n" || "$ch" == "N" ]; then
        return 1
    fi
    return 0
}

install_dir() {
    [ -d "$DIRNAME/$1" ] || die '! Not found '"$1";
    [ -d "$HOME/$1" ] && die '! Not overwriting. Please delete '"$HOME/$1"' before proceeding.';
    ln -s "$DIRNAME/$1" "$HOME/$1" 
}

oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        return 1
    fi
    echo 'Installing oh-my-zsh...';
    SCRIPT=''
    which curl &> /dev/null && SCRIPT="$(curl -fsSL "$OH_MY_ZSH_URL")"
    which wget &> /dev/null && SCRIPT="$(wget "$OH_MY_ZSH_URL" -O -)"
    [ -z "$SCRIPT" ] && die 'Could not find curl or wget.'
    sh -c "$SCRIPT"
}

oh_my_zsh_powerlevel10k() {
    echo 'Installing powerlevel10k...';
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
}

install_paru() {
    OLD_PWD=`pwd`
    cd "$HOME/.cache"
    git clone https://aur.archlinux.org/paru.git paru
    cd "paru"
    makepkg -si
    cd "$OLD_PWD"
}

install_sway() {
    echo "Installing sway dotfiles..."
    for dir in ${SWAY_FILES[@]}; do
        install_dir "$dir"
    done

    echo ""
    echo "Installing packages..."
    # let user see the command they're running before inserting password
    bash -x -c "paru -S ${SWAY_DEPS[@]}"

    echo ""
    echo "Enabling systemd services..."
    bash -x -c "sudo systemctl enable ${SWAY_SYSTEMD_SERVICES[@]}"
}


[ -z "$HOME" ] && die '$HOME is empty.'; 

# config
INSTALL_OH_MY_ZSH=`choice "Do you want to install oh-my-zsh and powerline10k?"; echo $?`
INSTALL_PARU=`choice "Do you want to install paru and configure it?"; echo $?`
INSTALL_SWAY=`choice "Do you want to install sway and dependencies? (paru needed!)"; echo $?`

echo 'Running git submodule update --init...'
git submodule update --init

for dir in ${NEEDS[@]}; do
    [ -d "$HOME/$dir" ] || die '! Not found '"$HOME/$dir";
done

# dotfiles installation
echo 'Installing the dotfiles...';
for file in ${FILES[@]}; do
    [ -f "$DIRNAME/$file" ] || die '! Not found '"$file";
    [ -f "$HOME/$file" ] && die '! Not overwriting. Please delete '"$HOME/$file"' before proceeding.';
    ln -s "$DIRNAME/$file" "$HOME/$file";
done

for dir in ${DIRECTORIES[@]}; do 
    install_dir "$dir"
done
echo 'Done!'

echo ''

# oh-my-zsh installation
test "$INSTALL_OH_MY_ZSH" == "0" && oh_my_zsh

# paru
test "$INSTALL_PARU" == "0" && install_paru

# sway & deps
test "$INSTALL_SWAY" == "0" && install_sway

