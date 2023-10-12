
export PATH="${PATH:+${PATH}:}$HOME/perl5/bin/"
export PATH="${PATH:+${PATH}:}$META_HOME/devel/repositories/rakudo/install/bin/"
export PATH="${PATH:+${PATH}:}$META_HOME/devel/repositories/rakudo/install/share/perl6/site/bin/"


#export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:~/perl5"
#export PERL_MB_OPT="--install_base ~/perl5"
#export PERL_MM_OPT="INSTALL_BASE=~/perl5"
#export PERL5LIB="/home/nadim/perl5/lib/perl5:$PERL5LIB"

export PERLDOC="-MPod::Text::Color::Delight"

alias pm='perldoc'
complete -F ? pm

alias pf='perldoc -f'
complete -F ? pm

alias r6='rakudo -Ilib,t'
alias t6='PERL6LIB=lib,t prove -v -j 9 -e rakudo'

#if which plenv > /dev/null; then eval "$(plenv init -)"; fi

source ~/perl5/perlbrew/etc/bashrc
source ~/perl5/perlbrew/etc/perlbrew-completion.bash

PERL5LIB="/home/tom-kubuntu/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/tom-kubuntu/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/tom-kubuntu/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/tom-kubuntu/perl5"; export PERL_MM_OPT;

