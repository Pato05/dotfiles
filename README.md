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

Yes, it is a simple bash script invoked whenever function keys are pressed, that displays a fancy mako notification (via notify-send) with the category=flyout, which is styled in a custom way inside mako's config to make it seem an actual flyout. It is also displayed above all windows (including full-screen ones, via layout=overlay).

## Screenshots

![screenshot-1](https://raw.githubusercontent.com/Pato05/dotfiles/main/screenshots/screenshot-1.png)
![screenshot-2](https://raw.githubusercontent.com/Pato05/dotfiles/main/screenshots/screenshot-2.png)
![screenshot-swaylock](https://raw.githubusercontent.com/Pato05/dotfiles/main/screenshots/screenshot-swaylock.png)
