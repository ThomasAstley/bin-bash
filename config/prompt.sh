
# bash 4.4
#export PS0="\e[38;5;236moutput on: \d \T \D{%pw %Z}$RESET\n"

# support fonction for copy to clipboard app
__copy_app_match_my_prompt()
{
if (( MINI_GIT )) ; then
	printf '^(\\\\033\\[[^m]+m)?(✔|✘)\ ' ; # the way it looks in a tmux buffer
else
	printf '^(\\\\033\\[[^m]+m)?[[:digit:]]+\ ' ; 
fi
}
export -f __copy_app_match_my_prompt

prompt_normal() { git_mini_prompt 0 ; PROMPT_COMMAND='show_prompt_normal' ; }
prompt_mini() { git_mini_prompt 1 ; PROMPT_COMMAND='show_prompt_mini' ; }
prompt_git_reduced() { NO_FULL_GIT="$1" ; }

#source "$(brew --prefix)/opt/gitstatus/gitstatus.plugin.sh"
source "/home/tom-kubuntu/tom/devel/gitstatus/gitstatus.plugin.sh"
gitstatus_stop && gitstatus_start -s -1 -u -1 -c -1 -d -1 ;

gitstatus_prompt() 
{
gitstatus_query                       || return 1  # error
[[ "$VCS_STATUS_RESULT" == ok-sync ]] || return 0  # not a git repo

local p

local where  # branch name, tag or commit
if [[ -n "$VCS_STATUS_LOCAL_BRANCH" ]]
	then
		where="$VCS_STATUS_LOCAL_BRANCH"
	elif [[ -n "$VCS_STATUS_TAG" ]]; then
		p+="#"
		where="$VCS_STATUS_TAG"
	else
		p+="@"
		where="${VCS_STATUS_COMMIT:0:8}"
	fi

[[ "$1" != --short ]] && 
	{
	(( ${#where} > 32 )) && where="${where:0:12}…${where: -12}"  # truncate long branch names and tags
	p+="$where"

	# ⇣42 if behind the remote.
	(( VCS_STATUS_COMMITS_BEHIND )) && p+=" ${VCS_STATUS_COMMITS_BEHIND}⇣"

	# ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
	(( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && p+=" "
	(( VCS_STATUS_COMMITS_AHEAD  )) && p+="${VCS_STATUS_COMMITS_AHEAD}⇡"

	# ⇠42 if behind the push remote.
	(( VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+=" ⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
	(( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+=" "

	# ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
	(( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && p+="⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"

	# *42 if have stashes.
	(( VCS_STATUS_STASHES        )) && p+=" ${VCS_STATUS_STASHES}s"

	# 'merge' if the repo is in an unusual state.
	[[ -n "$VCS_STATUS_ACTION"   ]] && p+=" ${VCS_STATUS_ACTION}"

	# ~42 if have merge conflicts.
	(( VCS_STATUS_NUM_CONFLICTED )) && p+=" conflicts: ${VCS_STATUS_NUM_CONFLICTED}"

	p+=' '

	# +42 if have staged changes.
	(( VCS_STATUS_NUM_STAGED     )) && p+="${VCS_STATUS_NUM_STAGED}ₛ"
	(( VCS_STATUS_NUM_UNSTAGED   )) && p+="${VCS_STATUS_NUM_UNSTAGED}ₘ"
	(( VCS_STATUS_NUM_UNTRACKED  )) && p+="${VCS_STATUS_NUM_UNTRACKED}ᵤ"

	echo -n "$p "
	} ||
	{
	(( VCS_STATUS_NUM_STAGED     )) && p+="${VCS_STATUS_NUM_STAGED}ₛ"
	(( VCS_STATUS_NUM_UNSTAGED   )) && p+="${VCS_STATUS_NUM_UNSTAGED}ₘ"
	# (( VCS_STATUS_NUM_UNTRACKED  )) && p+="${VCS_STATUS_NUM_UNTRACKED}ᵤ"

	[[ "$p" ]] && echo -n "$p "
	}
}

show_prompt_normal() 
{
[[ $? -eq 0 ]] && STATUS="\[$BLUE\]" || STATUS="\[$RED\]"
[[ $USER == "nadim" ]] && WHO= || WHO="\[$GREEN\]\u@\h" 
dir_stack=`dirs -p |  wc -l` ; [[ "$dir_stack" -lt 2 ]] && dir_stack= || dir_stack="[$dir_stack]"

(($(tmux list-windows | wc -l) ==  1)) && T="\[${MAGENTA}T \]" || T=

PS1='${debian_chroot:+($debian_chroot)}'
PS1+="$STATUS$(history | wc -l) $T$WHO\[$BLUE\]$dir_stack\w"
#PS1+="\[$DIM_CYAN\]$(tmuxslider-status)\[$YELLOW\]$(gitstatus_prompt)\[$MAGENTA\]$(GIT_DIR=.gv gitstatus_prompt --short)\[$CYAN\]$(tmuxake status)\[$RESET\]"
PS1+="\[$YELLOW\]$(gitstatus_prompt)\[$MAGENTA\]$(GIT_DIR=.gv gitstatus_prompt --short)\[$RESET\] "
# PS1+="\[$DIM_CYAN\]$(tmuxslider-status)\[$YELLOW\]\[$CYAN\]$$(tmuxake status)\[$RESET\]"

tmux-refresh-status
}

tmuxslider-status() { status=$(tmuxslider status) ; [[ $status == "[0]" ]] && echo ' ' || echo "$status " ; }

show_prompt_mini() 
{
[[ $? -eq 0 ]] && PS1="\[$BLUE\]✔ " || PS1="\[$RED\]✘ "
PS1+="\[$CYAN\]$(tmuxake status)\[$RESET\]"

tmux-refresh-status
}

PROMPT_DIRTRIM=1
prompt_normal

