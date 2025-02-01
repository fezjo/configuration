# set fish_function_path $fish_function_path $HOME/src/plugin-foreign-env/functions/

set -l HERE "config.fish"

if status is-interactive
    # Commands to run in interactive sessions can go here
end

if status is-login && test -e /etc/profile
    bass source /etc/profile
end

# source $HOME/.config/fish/conf.d/profile
# bass source $HOME/.profile $HERE
source $HOME/.config/shell-config.fish $HERE

bind \cw backward-kill-word
bind \b backward-kill-word
bind \e\[3\;5~ kill-word

# /home/fezjo/src/justthetip/tipper.sh
