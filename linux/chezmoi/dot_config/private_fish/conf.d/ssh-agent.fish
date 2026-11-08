# ssh-agent: use the systemd user socket, which starts the agent on demand.
# Stable path, no need to eval ssh-agent output or track a PID.
if set -q XDG_RUNTIME_DIR
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
end

# ssh_fezjo has no passphrase, so load it whenever the agent is empty.
if set -q SSH_AUTH_SOCK; and not ssh-add -l >/dev/null 2>&1
    ssh-add -q ~/.ssh/ssh_fezjo >/dev/null 2>&1
end
