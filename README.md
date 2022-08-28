# dotfiles

A repository containing my dotfiles, so that I can easily restore my configuration on new machines (being it a Windows or Linux machine)

## Installing

If on a new Arch install, it is not guaranteed to work in chroot, but rather, run this in a tty after installing.

```bash
git clone https://github.com/Pato05/dotfiles "$HOME/.dotfiles"
$HOME/.dotfiles/install.sh
```

-   Change the $home variable inside .config/sway/config
-   You should be good to go

## Flyout?

Yes, it is a simple bash script, that is started inside a terminal which shows the current volume or brightness, ~~and executes a bunch of `swaymsg` commands to place itself at the bottom of the screen (however, for some reason, sometimes this fails)~~ if you're on a single-screen configuration / all screens have the same dimensions, you can enter `$HOME/.config/sway/scripts/get_flyout_coords.sh` and put the copied coords into the sway config to avoid those issues.

Sadly I haven't found a way to show it on top of all windows so far, so if, for example, you had Chrome on full screen, it wouldn't show, which kinda defeats the purpose of a flyout.

## Screenshots

![screenshot-1](https://raw.githubusercontent.com/Pato05/dotfiles/main/screenshots/screenshot-1.png)
![screenshot-2](https://raw.githubusercontent.com/Pato05/dotfiles/main/screenshots/screenshot-2.png)
