sh pre-installation.sh
sed 's/#.*//; s/^\s*//; /^-/d; /^\s*$/d; s/^+ //' packages.md | yay -S --needed -
sh post-installation.sh
