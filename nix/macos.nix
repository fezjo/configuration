{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # macOS-specific utilities
        coreutils
        findutils
        gnu-sed
        gnu-tar
        gnu-time

    # Package management
        homebrew

    # Window management
        alt-tab
        nikitabobko/tap/aerospace
        FelixKratz/formulae/borders

    # Input managment
        karabiner-elements
        mac-mouse-fix
        middleclick
        ukelele

    # Virtualization
        utm
  ];
}
