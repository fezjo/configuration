#!/usr/bin/fish

set -gx ENV_PROFILES "$ENV_PROFILES\n($(date))>by $argv[1]>shell-config.fish>start"

set source_commands \
    # "thefuck --alias" \
    "basrs source $HOME/.profile $HERE" \
    "mise activate fish" \
    "zoxide init fish" \
    ""

if test -d /opt/homebrew
    set -p source_commands "/opt/homebrew/bin/brew shellenv"
end

for cmd in $source_commands
    eval "$cmd" | source
end

function fuck -d "Correct your previous console command"
    set -l fucked_up_command $history[1]
    env TF_SHELL=fish TF_ALIAS=fuck PYTHONIOENCODING=utf-8 thefuck $fucked_up_command THEFUCK_ARGUMENT_PLACEHOLDER $argv | read -l unfucked_command
    if [ "$unfucked_command" != "" ]
        eval $unfucked_command
        builtin history delete --exact --case-sensitive -- $fucked_up_command
        builtin history merge
    end
end

set -gx GPG_TTY (tty)

set -gx ENV_PROFILES "$ENV_PROFILES\n($(date))>by $argv[1]>shell-config.fish>end"
