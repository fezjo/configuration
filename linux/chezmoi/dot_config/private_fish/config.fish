# set fish_function_path $fish_function_path $HOME/src/plugin-foreign-env/functions/

if status is-interactive
    # Commands to run in interactive sessions can go here
end

if status is-login && test -e /etc/profile
    bass source /etc/profile
end

bass source $HOME/.profile
source $HOME/.config/shell-config.fish

bind \cw backward-kill-word
bind \b backward-kill-word
bind \e\[3\;5~ kill-word

set -gx EDITOR helix

sh /home/fezjo/src/justthetip/tipper.sh
