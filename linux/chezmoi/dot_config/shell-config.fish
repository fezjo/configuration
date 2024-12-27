#!/usr/bin/fish

set -gx ENV_PROFILES "$ENV_PROFILES:shell-config.fish/start"

mise activate fish | source

thefuck --alias | source

zoxide init fish | source

set -gx ENV_PROFILES "$ENV_PROFILES:shell-config.fish/end"