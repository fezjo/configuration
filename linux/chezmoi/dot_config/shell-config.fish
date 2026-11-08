# Integrations for fish. Source after the environment.
if type -q mise
    mise activate fish | source
end
if type -q zoxide
    zoxide init fish | source
end
if set -q XDG_RUNTIME_DIR
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
end
if isatty
    set -gx GPG_TTY (tty)
end
