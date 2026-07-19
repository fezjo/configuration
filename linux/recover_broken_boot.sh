#!/bin/bash

set -e

sudo cryptsetup luksOpen /dev/nvme0n1p5 cryptroot

# Option 1:
# sudo mount /dev/mapper/cryptroot /mnt -o subvol=@
# sudo mount /dev/mapper/cryptroot /mnt/home -o subvol=@home
# sudo mount /dev/mapper/cryptroot /mnt/var/cache -o subvol=@cache
# sudo mount /dev/mapper/cryptroot /mnt/var/log -o subvol=@log
# sudo mount /dev/nvme0n1p1 /mnt/boot
# sudo arch-chroot /mnt

# Option 2:
# sudo mount /dev/mapper/cryptroot /mnt -o subvol=@
# sudo mount -a -T /mnt/etc/fstab -R /mnt
# sudo arch-chroot /mnt

# Option 3:
sudo mount /dev/mapper/cryptroot /mnt -o subvol=@
sudo arch-chroot /mnt
mount -a

sudo pacman -Sy linux
