# Integrations for fish. Source after the environment.

# Reuse the POSIX alias file instead of maintaining a second fish list.
if type -q basrs
    basrs source $HOME/.config/shell/aliases.sh | source
end

if type -q mise
    mise activate fish | source
end
if type -q zoxide
    zoxide init fish | source
end
if not set -q SSH_AUTH_SOCK; and set -q XDG_RUNTIME_DIR
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
end
if isatty
    set -gx GPG_TTY (tty)
end
