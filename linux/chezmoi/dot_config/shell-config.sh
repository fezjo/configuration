# Integrations shared by bash and zsh. Source after the environment.
if [ -n "${BASH_VERSION:-}" ]; then
    __shell=bash
elif [ -n "${ZSH_VERSION:-}" ]; then
    __shell=zsh
else
    return 0 2>/dev/null || exit 0
fi

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate "$__shell")"
fi
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init "$__shell")"
fi
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
    SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
    export SSH_AUTH_SOCK
fi
if [ -t 0 ]; then
    GPG_TTY=$(tty)
    export GPG_TTY
fi
unset __shell
