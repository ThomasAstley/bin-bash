#!/bin/bash

source ~/tom/bin/completions/bash_completion_tmux.sh

# ftl binding in "$META_HOME/config/ftl.sh" 

# tmux-power-zoom, Z
# tmux-butler,     C-w C-p C-l
# tmux-fuzzback,   ?,     fuzzy search to position in buffer,
# extrakto,        TAB,   fuzzy search all words in buffer, insert
# tmux-thumbs,     space, hint based selection

tmux bind -Troot        C-g switch-client -Ttable_ctl_g

tmux bind -Ttable_ctl_g C-k popup -w 80% -h 80% -E -d "#{pane_current_path}" tmux_get_klipper
tmux bind -Ttable_ctl_g C-h popup -w 80% -h 80% -E -d "#{pane_current_path}" tmux_get_sha
tmux bind -Ttable_ctl_g C-f popup -w 80% -h 80% -E -d "#{pane_current_path}" tmux_get_file
tmux bind -Ttable_ctl_g C-g run   "tmux display -p '#{pane_id}'>/tmp/tmux_ftll_destination_pane" \\\; new-window -c "#{pane_current_path}" "tmux_get_ftl"
tmux bind -Ttable_ctl_g C-t run   "tmux display -p '#{pane_id}'>/tmp/tmux_fzf-tldr_destination_pane" \\\; new-window -c "#{pane_current_path}" "tmux_fzf-tldr"

tmux bind -Ttable_ctl_g C-c run   "history | tail -n 2 | head -n 1 | perl -pe 's/^\s*[0-9]+\s*//' | tr -d '\n' | copy"

tmux bind -Ttable_ctl_g C-v switch-client -Ttable_ctl_v

tmux bind -Ttable_ctl_v C-e new-window -c "#{pane_current_path" "vim -p -c ':call FZFPickNkh()|tabo'"
tmux bind -Ttable_ctl_v C-h new-window -c "#{pane_current_path" "vim -p -c ':FZFMru'"
tmux bind -Ttable_ctl_v C-v new-window -c "#{pane_current_path" 'tmp=$(mktemp -p /tmp XXXXXXXX) ftl 3>\$tmp ; vim -p $(cat \$tmp)'

# command specific windows ---------------------------------------------------
tmux bind r      new-window -c '#{pane_current_path}' -n ranger ranger
tmux bind C-?    switch-client -t cmus

tmux bind h      split-window -v -l 7 htop

tmux bind m      new-window  fzf_man2

# tmux bind m      new-window  'while : ; do page="$(. ~/.bashrc &>/dev/null ; man -k . -s 1,3 | sort -u | piper ".*?\W-" blue | fzf --ansi --cycle -q ^ | cut -d" " -f1)" ; [[ $page ]] && man2 $page ; read -sn1 ; [[ "$REPLY" == "q" ]] && exit ; done'

tmux bind C-M    run "tmux-man"

tmux bind g      split-window c_fzf
tmux bind C-G    new-window -n cheat c_fzf

tmux bind k      split-window -h -l 21 'tcol --oc'

# new window via fzf-mark ----------------------------------------------------
tmux bind C-C    new-window -c "#{pane_current_path}" "cd \$(tmux_new_window_fzm) ; bash -i" 

# new session ----------------------------------------------------------------
tmux bind v run 'U=$(hexdump -n 4 -v -e "/1 \"%02X\"" /dev/urandom) ; tmux new-session -d -s $U ; tmux switch-client -t $U ; tmux send-keys -t $U c d t'

# tmuxake --------------------------------------------------------------------
rm ~/.tmux/plugins/tmuxake/pids/$$ 2> /dev/null

#tmux bind -Tprefix Tab switch -Ttab
#tmux bind -Ttab Tab run-shell "/home/nadim/nadim/bin/bash/tmuxake switch"

# when not using tmuxake -----------------------------------------------------
#tmux bind -r C-p switch-client -p
#tmux bind -r C-n switch-client -n

# when using tmuxake, skip tmuxake session -----------------------------------
# tmux bind -r C-p run "/home/nadim/nadim/bin/bash/tmuxake client-previous" 
# tmux bind -r C-n run "/home/nadim/nadim/bin/bash/tmuxake client-next" 


# tmux bind Tab run "/home/nadim/nadim/bin/bash/tmuxake toggle"
tmux bind C-a run "/home/nadim/nadim/bin/bash/tmuxake toggle" 
tmux bind BSpace run "/home/nadim/nadim/bin/bash/tmuxake close" 

# tmux bind C-t run "/home/nadim/nadim/bin/bash/tmuxake position t" 
# tmux bind C-b run "/home/nadim/nadim/bin/bash/tmuxake position b" 
# tmux bind C-l run "/home/nadim/nadim/bin/bash/tmuxake position l" 
# tmux bind C-r run "/home/nadim/nadim/bin/bash/tmuxake position r" 
# tmux bind C-f run "/home/nadim/nadim/bin/bash/tmuxake position f" 

# tmuxslider -----------------------------------------------------------------
# tmux bind C-T    run "/home/nadim/nadim/bin/bash/tmuxslider create"
# tmux bind -r C-Y run "/home/nadim/nadim/bin/tmuxslider next"
# tmux bind -r C-R run "/home/nadim/nadim/bin/tmuxslider previous"
# tmux bind -r C-C run "/home/nadim/nadim/bin/tmuxslider close"
# tmux bind  C-V   run "/home/nadim/nadim/bin/tmuxslider close-all"
# tmux bind  C-E   run "/home/nadim/nadim/bin/tmuxslider break"

# ----------------------------------------------------------------------------

tmux set-environment META_HOME '/home/nadim/nadim' 
tmux set-environment TMUXAKE_SOURCE '~/nadim/config/tmuxake-prompt' 

alias tmsr='tmux-split-run'
alias tmsri='tmux-split-run-interactive'
alias tmr='tmux move-window -r'
alias tmt='tmuxslider create'

tmrc() { clear ; tmux clear-history ; eval "$*" ; sleep 0.03 ; tmux copy-mode ; }
tmux-ls() { tabs 4 ; $(which tmux-ls) $@ ; tabs 8  ; }
tmux-run() { tmux new-window -c "#{pane_current_path}" "$* ; /bin/bash" ; }
tmux-split-run() { tmux split-window "$1 $2 $3 $4 $5 $6 ; read" ; }
tmux-split-run-interactive() { tmux split-window "$1 $2 $3 $4 $5 $6" ; }

tmux-search() { tmux copy-mode; tmux send-keys /$1 enter ; }
tmux-refresh-status() { tmux refresh-client -S ; }

function _tmuxake_completion
{
completion_list="toggle full attach detach break import push pop close position check kill status status2"
 
local cur prev
COMPREPLY=()
cur="${COMP_WORDS[COMP_CWORD]}"
COMPREPLY=( $(compgen -W "${completion_list}" -- ${cur}) )

return 0
}

complete -o nospace -F _tmuxake_completion tmuxake

