# Return if there is no git
which git > /dev/null 2>&1 || return 0

# export PATH=/usr/local/git/bin:$PATH
# export MANPATH=/usr/local/git/share/man:/usr/local/gitmanpages:$MANPATH

# Prompt
if type __git_ps1 >/dev/null 2>&1; then
  export GIT_PS1_SHOWDIRTYSTATE=1
  export GIT_PS1_SHOWSTASHSTATE=1
  export GIT_PS1_SHOWUNTRACKEDFILES=1
  export GIT_PS1_SHOWCOLORHINTS=1
  export PROMPT_COMMAND='__git_ps1 "\D{%H%M} \h:\w" " \u\\$ " " [%s]"; history -a'
fi

alias g="git"
alias gl="g l"

# Make bash completion work with the g alias
complete -o bashdefault -o default -o nospace -F _git g 2>/dev/null || complete -o default -o nospace -F _git g
