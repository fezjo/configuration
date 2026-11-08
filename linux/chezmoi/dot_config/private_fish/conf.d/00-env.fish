# Load the single environment source for fish login/TTY sessions.
# Uses sh so environment.d variable expansion behaves the same as in bash/zsh.
set -l keys PATH
for f in $HOME/.config/environment.d/*.conf
    test -r $f; or continue
    for line in (string match -v '^\s*[#;]' < $f)
        test -n "$line"; or continue
        set -l kv (string split -m1 = -- $line)
        test (count $kv) -eq 2; or continue
        set -a keys $kv[1]
    end
end

set -l env_path (string join : $PATH)
set -l envargs HOME=$HOME PATH=$env_path USER=$USER SHELL=$SHELL
if set -q XDG_RUNTIME_DIR
    set -a envargs XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
end

for line in (env -i $envargs sh -c 'set -a; . "$HOME/.config/shell/env.sh"; env -0' | string split0)
    set -l kv (string split -m1 = -- $line)
    test (count $kv) -eq 2; or continue
    contains -- $kv[1] $keys; or continue
    set -gx $kv[1] $kv[2]
end
