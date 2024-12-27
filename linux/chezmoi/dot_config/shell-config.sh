#!/bin/bash

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

eval "$(mise activate zsh)"

eval "$(thefuck --alias)"

eval "$(zoxide init zsh)"

export PYENV_ROOT="$HOME/.local/share/pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PATH:$PYENV_ROOT/bin"
# eval "$(pyenv init -)"

# eval "$(antidot init)"