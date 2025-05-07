{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sway
    swaylock
    swayidle
    sway-systemd
    waybar
  ];
}
