{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    hyperland
    xdg-desktop-portal-hyprland
    waybar
  ];
}
