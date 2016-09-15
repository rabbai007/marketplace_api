# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin:/usr/sbin:/usr/bin:/bin:/sbin

export PATH

set -o vi

alias l='ls -ltr'
alias cdl='cd /www/a/logs/ActiveMQ; l'
alias cdp='cd /usr/ActiveMQ/conf; l'

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
