HISTCONTROL=ignoreboth
HISTSIZE=100000
HISTFILESIZE=100000
HISTIGNORE="l:ll::lll:ls:history:u:f:clear:reset"

export LC_ALL=en_US.UTF-8
export PS1="\D{%H%M} \h:\w \u\\$ "
export EDITOR=vi
export PATH=$HOME/bin:$CONFIG_ROOT/bin:$PATH
export IGNOREEOF=2

alias ..="cd .."
alias c="cd -P"
alias mv="mv -i"

if $OS_OSX ; then
  alias l="ls -alGvhT"
else
  alias l="ls -alvh --color=auto"
fi

shopt -s cdspell
shopt -s histappend

# Make path_helper set MANPATH from /etc/manpaths.d/*
# TODO: check if this is needed
# export MANPATH=
# if [ -x /usr/libexec/path_helper ]; then
#   eval `/usr/libexec/path_helper -s`
# fi
#
# export PATH=/usr/local/bin:/usr/local/sbin:$PATH
