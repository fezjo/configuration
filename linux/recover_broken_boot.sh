#!/bin/bash

set -e

sudo cryptsetup luksOpen /dev/nvme0n1p5 cryptroot

sudo mount /dev/mapper/cryptroot /mnt -o subvol=@ 
sudo mount /dev/mapper/cryptroot /mnt/home -o subvol=@home                                   
sudo mount /dev/mapper/cryptroot /mnt/var/cache -o subvol=@cache                             
sudo mount /dev/mapper/cryptroot /mnt/var/log -o subvol=@log                             
sudo mount /dev/nvme0n1p1 /mnt/boot

sudo arch-chroot /mnt

sudo pacman -Sy linux
