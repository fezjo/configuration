#!/bin/bash

export ENV_PROFILES="$ENV_PROFILES\n($(date))>by $1>shell-config.sh>start"

SHELLNAME=$(basename "$(ps -p $$ -o comm=)")

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

eval "$(mise activate $SHELLNAME)"

# NOTE: this takes a long time (~150ms)
eval "$(thefuck --alias)"

eval "$(zoxide init $SHELLNAME)"

export PYENV_ROOT="$HOME/.local/share/pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PATH:$PYENV_ROOT/bin"
# eval "$(pyenv init -)"

# eval "$(antidot init)"

export ENV_PROFILES="$ENV_PROFILES\n($(date))>by $1>shell-config.sh>end"
