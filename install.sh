#!/bin/bash
NEEDS=(.config)
FILES=(.vimrc .zshrc .gitconfig .p10k.zsh)
DIRECTORIES=(.config/mpv)

DIRNAME="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

die() {
    echo $@;
    exit 1;
}

oh_my_zsh() {
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

[ -z "$HOME" ] && die '$HOME is empty.'; 

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
    [ -d "$DIRNAME/$dir" ] || die '! Not found '"$dir";
    [ -d "$HOME/$dir" ] && die '! Not overwriting. Please delete '"$HOME/$dir"' before proceeding.';
    ln -s "$DIRNAME/$dir" "$HOME/$dir"
done
echo 'Done!'

echo ''
# oh-my-zsh installation
echo 'Do you want to install oh-my-zsh and powerlevel10k? [Y/n] '
read -n 1 ch

if ! [ "$ch" == "n" || "$ch" == "N" ]; then
    [ -d "$HOME/.oh-my-zsh" ] && echo '! Oh My Zsh is already installed!' || { oh_my_zsh && oh_my_zsh_powerlevel10k }  
fi
