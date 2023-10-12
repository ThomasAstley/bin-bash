# load docker completion
. /usr/share/bash-completion/completions/docker >/dev/null 2>&1 

alias d=docker
complete -F _docker d

# extract columns interactively 
di()	{ _dcol	'image ls'	2		; }
din()	{ _dcol	'image ls'	0	1	; }
dc()	{ _dcol	'container ls'	1		; }
dci()	{ _dcol	'container ls'	2		; }
dp()	{ _dcol	'ps'		0		; }
dpa()	{ _dcol	'ps -a'		0		; }
dpai()	{ _dcol	'ps -a'		1		; }

_dcol() { _dgs $1 | perl -e 'while(<STDIN>) { print join(":", (split)[@ARGV]) ."\n" }' ${*:2} ; }
_dgs() { docker $* | tail -n +2 | fzf --header "$(docker $* | head -n 1)" -m -0 --bind ctrl-t:toggle-all ; } 

alias dr=docker_run
alias dri=docker_run_interactive

alias dit=docker_image_tag
alias __dir=docker_image_remove

alias dco=docker_commit
alias dcr=docker_container_rm

docker_run()		{ _interactive_docker	'di'			'run'		$* ; }
docker_run_interactive(){ _interactive_docker	'di | head -n 1'	'run -it'	$* ; }

docker_image_tag()	{ _interactive_docker	'di | head -n 1'	'image tag'	$* ; }
docker_image_remove()	{ _interactive_docker	'din'			'rm'		$* ; }

docker_commit()		{ _interactive_docker 	'dc'			'commit'	$* ; }
docker_container_rm()	{ _interactive_docker 	'dpa'			'rm'		$* ; }

_interactive_docker()	{ for s in $( eval $1 ) ; do docker $2 "$s" ${*:3} ; done ; }

# add completion via fzf with ',' directly on the command line
#source /home/nadim/nadim/devel/repositories/docker-fzf-completion/docker-fzf.bash
export FZF_COMPLETION_TRIGGER=','

