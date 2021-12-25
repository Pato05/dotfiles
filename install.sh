#!/bin/bash
NEEDS=(.config)
FILES=(.vimrc .zshrc .gitconfig)
DIRECTORIES=(.config/mpv)

DIRNAME="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

die() {
    echo $@;
    exit 1;
}

[ -z "$HOME" ] && die '$HOME is empty.'; 

for dir in ${NEEDS[@]}; do
    [ -d "$HOME/$dir" ] || die '! Not found '"$HOME/$dir";
done

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
