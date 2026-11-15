# Packages needed only when installing a new machine.
# `setup.sh sync` never installs these, so an existing machine keeps its
# current kernel, initramfs tooling, and boot setup.

+ base
+ base-devel
+ linux
+ linux-headers
+ linux-lts
+ linux-lts-headers
+ mkinitcpio
+ efibootmgr
+ arch-install-scripts
