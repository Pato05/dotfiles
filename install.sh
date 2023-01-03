#!/bin/bash
NEEDS=(.config)
FILES=(.zshrc .gitconfig .p10k.zsh)
DIRECTORIES=(.config/mpv .config/foot .config/nvim)

SWAY_FILES=(.config/sway .config/waybar .config/swaylock .config/mako .sway-launcher-desktop)
SWAY_DEPS=(
    # sway stuff
    sway
    swaylock
    swayidle
    swayimg
    swaybg
    waybar
    # CLI utils
    brightnessctl
    yt-dlp
    # other criticals
    pavucontrol
    blueberry
    pavucontrol
    mako
    noto-fonts-emoji
    file-roller
    pamixer
    imagemagick
    jq
    foot
    grim
    slurp
    wl-clipboard
    pipewire
    wireplumber
    mpv
    mpv-mpris
    grimshot
    # icons font
    ttf-material-design-icons-git
    # greeter
    greetd
    greetd-gtkgreet
    # icon theme
    papirus-icon-theme
    gtk3-classic
    # manual
    man-db
    # for bluetooth module
    cppbtbl
)
SWAY_SYSTEMD_SERVICES=(greetd.service)

DIRNAME="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

die() {
    echo $@;
    exit 1
}

# choice prompt
choice() {
    echo -n "$@ [y/N] "
    read -n 1 ch
    echo ''

    if ! [[ "$ch" == "n" || "$ch" == "N" ]]; then
        return 0
    fi
    return 1
}

install_dir() {
    [ -d "$DIRNAME/$1" ] || die '! Not found '"$1";
    [ -d "$HOME/$1" ] && die '! Not overwriting. Please delete '"$HOME/$1"' before proceeding.';
    ln -s "$DIRNAME/$1" "$HOME/$1" 
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        return 1
    fi
    echo 'Installing oh-my-zsh...';
    SCRIPT=''
    which curl &> /dev/null && SCRIPT="$(curl -fsSL "$OH_MY_ZSH_URL")"
    which wget &> /dev/null && SCRIPT="$(wget "$OH_MY_ZSH_URL" -O -)"
    [ -z "$SCRIPT" ] && die 'Could not find curl or wget.'
    env CHSH=no RUNZSH=no KEEP_ZSHRC=yes sh -c "$SCRIPT"
    bash -x -c "doas chsh -s $(which zsh)"

    echo '';
    echo 'Installing powerlevel10k...';
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

    echo '';
    echo 'Installing zsh-autosuggestions...';
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    echo '';
    echo 'Installing zsh-syntax-highlighting'
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

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
    bash -x -c "doas systemctl enable ${SWAY_SYSTEMD_SERVICES[@]}"

    echo "Installing catppuccin's papirus-folders icons"
    bash -x -c "doas cp -r '$DIRNAME/papirus-folders' '/usr/share/icons/Papirus' && \
    doas "$DIRNAME/papirus-folders/papirus-folders" -C cat-mocha-lavender --theme Papirus-Dark"

    echo "Installing Papirus-Dark icon theme (for GTK)..."
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"

    echo "Installing GTK theme..."
    local THEME_NAME="Catppuccin-Mocha-xhdpi"
    echo "GTK_THEME=$THEME_NAME" | doas tee -a /etc/environment
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_NAME"

    echo "Telling Qt apps to use the GTK theme..."
    echo "QT_QPA_PLATFORMTHEME=gtk2" | doas tee -a /etc/environment

    echo "Telling Qt apps to run on wayland..."
    echo "QT_QPA_PLATFORM=wayland" | doas tee -a /etc/environment


}


[ -z "$HOME" ] && die '$HOME is empty.'; 

# config
choice "Do you want to install custom oh-my-zsh?"; INSTALL_OH_MY_ZSH=$?
choice "Do you want to install paru and configure it?"; INSTALL_PARU=$?
choice "Do you want to install sway and dependencies? (paru needed!)"; INSTALL_SWAY=$?

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
test "$INSTALL_OH_MY_ZSH" == "0" && install_oh_my_zsh

# paru
test "$INSTALL_PARU" == "0" && install_paru

# sway & deps
test "$INSTALL_SWAY" == "0" && install_sway

