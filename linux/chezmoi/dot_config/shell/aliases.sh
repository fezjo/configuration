# Portable interactive aliases for bash and zsh.
# Keep this file free of machine-specific paths.
#
# grep is intentionally not aliased. Use rg explicitly.
# alias grep='rg'
# alias egrep='rg'

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --classify=auto'
    alias ll='eza -al --group-directories-first --classify=auto'
    alias l='eza -al --group-directories-first --classify=auto'
else
    alias ls='ls --color=auto'
    alias ll='ls -al --color=auto'
    alias l='ls -al --color=auto'
fi

alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias ln='ln -v'
alias mkdir='mkdir -v'
alias rmdir='rmdir -v'
alias du='du -h --apparent-size'

if command -v rsync >/dev/null 2>&1; then
    alias rcp='rsync -v --progress'
    alias rmv='rsync -v --progress --remove-source-files'
    alias cpr='rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1'
    alias mvr='rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1 --remove-source-files'
    alias scpr='rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1 --compress'
fi

if command -v fd >/dev/null 2>&1; then
    alias fd='fd --exclude=/run'
fi
if command -v pypy3 >/dev/null 2>&1; then
    alias py='pypy3'
fi
if command -v xdg-open >/dev/null 2>&1; then
    alias xo='xdg-open'
    alias open='xdg-open'
fi
if command -v tokei >/dev/null 2>&1; then
    alias cloc='tokei'
fi
if command -v wl-copy >/dev/null 2>&1; then
    alias ctrlc='wl-copy'
fi
if command -v wl-paste >/dev/null 2>&1; then
    alias ctrlv='wl-paste'
fi
if command -v batman >/dev/null 2>&1; then
    alias man='batman'
fi

alias dyff='diff -W 80 --color=always --suppress-common-lines -y'
