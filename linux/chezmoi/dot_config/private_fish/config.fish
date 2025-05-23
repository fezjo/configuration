# set fish_function_path $fish_function_path $HOME/src/plugin-foreign-env/functions/

set -l HERE "config.fish"

if status is-interactive
    # Commands to run in interactive sessions can go here
end

if ! type -q basrs
    set basrs_path $HOME/.local/share/cargo/bin/basrs
    if test -f $basrs_path
        alias basrs=$basrs_path
    end
end

if status is-login && test -e /etc/profile
    basrs source /etc/profile | source
end

# source $HOME/.config/fish/conf.d/profile
# bass source $HOME/.profile $HERE
source $HOME/.config/shell-config.fish $HERE

bind \cw backward-kill-word
bind \b backward-kill-word
bind \e\[3\;5~ kill-word

# /home/fezjo/src/justthetip/tipper.sh
