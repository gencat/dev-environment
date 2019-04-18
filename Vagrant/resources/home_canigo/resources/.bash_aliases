unalias -a

# Some example alias instructions
# If these are enabled they will be used instead of any instructions
# they may mask.  For example, alias rm='rm -i' will mask the rm
# application.  To override the alias instruction use a \ before, ie
# \rm will call the real rm not the alias.
#
# Interactive operation...
 alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'
# Canigó: Millora de seguretat...
 alias chmod='chmod --preserve-root -c'
#
# Default to human readable figures
 alias df='df -h'
 alias du='du -h'
#
# Misc :)
 alias less='less -r'                          # raw control characters
 alias whence='type -a'                        # where, of a sort
 alias grep='grep --color'                     # show differences in colour
 alias egrep='egrep --color=auto'              # show differences in colour
 alias fgrep='fgrep --color=auto'              # show differences in colour
#
# Some shortcuts for different directory listings
 alias ls='ls -hF --color=tty'                 # classify files in colour
 alias dir='ll --color=auto -1'
 alias vdir='ls --color=auto --format=long'
 alias ll='ls -lA'
 alias la='ls -A'
 alias l='ls -CF'
 alias clear='/usr/bin/clear && /usr/bin/clear'
# Propis
 alias reload='source ~/.profile ; echo ~/.profile recarregat'
 #alias cd='pushd .>/dev/null; cd_func' # FUNCTION
 alias 'cd-'='popd>/dev/null'
 alias 'cd..'='cd ../'
 alias ..='cd ../'
## Entorns java
 alias java8='export JAVA_HOME=$JAVA_HOME8; export PATH=$JAVA_HOME/bin:$PATH'
 alias java11='export JAVA_HOME=$JAVA_HOME11; export PATH=$JAVA_HOME/bin:$PATH'
## Entorns node
 alias node8='export PATH=$NODE_V8/bin:$PATH'
 alias node10='export PATH=$NODE_V10/bin:$PATH'
