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
