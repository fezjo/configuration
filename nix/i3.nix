{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    i3-wm
    i3-exit
    i3lock
  ];
}
