complete -F _man man2
_completion_loader man

# edit_config
source $META_HOME/bin/bash/edit_config
alias e='edit_config'

# pbs
complete -o default -C "$META_HOME/devel/repositories/perl_modules/P5-PerlBuildSystem/pbs_completion_script" pbs

# hdr
#source "$META_HOME/devel/repositories/perl_modules/P5-Data-HexDump-Range/_hdr_completion"
complete -F _hdr_bash_completion -o default hdr

# tmsu
source "/home/nadim/no_backup/devel/repositories/TMSU/tmsu_bash_completion" 


