#!/usr/bin/env bash

# based on https://github.com/wfxr/forgit

__forgit_fzf() {
    FZF_DEFAULT_OPTS="
        $FZF_DEFAULT_OPTS
	+s
        --ansi
        --bind='alt-k:preview-up,alt-p:preview-up'
        --bind='alt-j:preview-down,alt-n:preview-down'
        --bind='ctrl-r:toggle-all'
        --bind='ctrl-s:toggle-sort'
        --bind='?:toggle-preview'
        --preview-window='right:70%'
        --bind='alt-w:toggle-preview-wrap'
        $FORGIT_FZF_DEFAULT_OPTS
    " fzf "$@"
}
        # --height '80%'

__forgit_color_to_grep_code() {
    case "$1" in
        black  ) echo -E '\[30m' ;;
        red    ) echo -E '\[31m' ;;
        green  ) echo -E '\[32m' ;;
        yellow ) echo -E '\[33m' ;;
        blue   ) echo -E '\[34m' ;;
        magenta) echo -E '\[35m' ;;
        cyan   ) echo -E '\[36m' ;;
        white  ) echo -E '\[97m' ;;
    esac
}

# diff is fancy with diff-so-fancy!
command -v diff-so-fancy >/dev/null 2>&1 && forgit_fancy='|diff-so-fancy'
command -v emojify >/dev/null 2>&1       && forgit_emojify='|emojify'

__forgit_inside_work_tree() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

__forgit_get_git_color() {
  local color=$(git config $1);
  color=${color:-$2}
  echo $(__forgit_color_to_grep_code $color)
}

# git commit browser
__forgit_log() {
  __forgit_inside_work_tree || return 1
  local cmd="echo {} |grep -o '[a-f0-9]\{7\}' |head -1 |xargs -I% git show --color=always % $forgit_emojify $@ $forgit_fancy"

  eval "git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr' $@ $forgit_emojify" |
      __forgit_fzf +s +m --tiebreak=index \
          --bind="enter:execute($cmd |LESS='-R' less)" \
          --bind="ctrl-y:execute-silent(echo {} |grep -o '[a-f0-9]\{7\}' |pbcopy)+abort" \
          --preview="$cmd"
  true
}

__forgit_diff()
{
__forgit_inside_work_tree || return 1

local cmd="git diff --no-ext-diff --color=always -- {} $forgit_emojify $forgit_fancy"

[[ $# -eq 0 ]] && local files=$(git rev-parse --show-toplevel) || local files="$@"

git ls-files --modified "$files"| lscolors |
	__forgit_fzf +m -0 \
		--bind="enter:execute($cmd |LESS='-R' less)" \
		--preview="$cmd"
}

__forgit_add() {

__forgit_inside_work_tree || return 1

added=$(__forgit_get_git_color "color.status.untracked" "red")
changed=$(__forgit_get_git_color "color.status.changed" "red")
unmerged=$(__forgit_get_git_color "color.status.unmerged" "red")

fga_fifo=$(mktemp -u -p /tmp/$USER fga_XXXXXXXX)
mkfifo $fga_fifo

local files=$(\
	git -c color.status=always status --short |
	grep -e "$added" -e "$changed" -e "$unmerged" |
	tr -d '"' |
	perl -e 'print sort { ($a =~ m~/~) <=> ($b =~ m~/~) } <STDIN>' |
	{ tee $fga_fifo | perl -lane 'print "@F[1..$#F]"' | paste -d' ' <(lscolors) <(<$fga_fifo awk '{print $1}') ; } |
	__forgit_fzf \
		-0 \
		-m \
		--nth 2..,.. \
		--preview="file=\$(echo {} | perl -pe 's/[ MUD?!]*$//') ; [[ -d "\$file" ]] && ls --color=always \"\$file\" || git ls-files --error-unmatch \"\$file\" &>/dev/null && { git diff --no-ext-diff --color=always -- \"\$file\" $forgit_fancy ; } || bat --theme="TwoDark" --plain --tabs=4 -n --color=always \"\$file\"" |
	perl -pe 's/[ MUD?!]*$//'
	)

rm $fga_fifo 

[[ -n "$files" ]] && { echo "$files" | xargs -I{} git add "{}" ; git status --short -uno ; }
}

__forgit_restore()
{
__forgit_inside_work_tree || return 1

local cmd="git diff --no-ext-diff --color=always -- {} $forgit_emojify $forgit_fancy"
local files=$(git ls-files --modified $(git rev-parse --show-toplevel) | lscolors | __forgit_fzf --ansi -m -0 --preview="$cmd")

[[ -n "$files" ]] && echo "$files" | xargs -I{} git checkout {} && git status --short -uno && return
}

__forgit_unstage()
{
__forgit_inside_work_tree || return 1

local cmd="git diff --cached --no-ext-diff --color=always -- {} $forgit_emojify $forgit_fancy"
local files=$(git diff --name-only --cached | lscolors | __forgit_fzf -m -0 --preview="$cmd")

[[ -n "$files" ]] && echo "$files" | xargs -I{} git reset HEAD {} && git status --short -uno && return
}

__forgit_clean() {
  __forgit_inside_work_tree || return 1
  # Note: Postfix '/' in directory path should be removed. Otherwise the directory itself will not be removed.
  local files=$(git clean -xdfn "$@"| awk '{print $3}'| __forgit_fzf -m -0 |sed 's#/$##')
  [[ -n "$files" ]] && echo "$files" |xargs -I{} git clean -xdf {} && return
  #echo 'Nothing to clean.'
}

__forgit_stash_show() {
  __forgit_inside_work_tree || return 1
  local cmd="git stash show \$(echo {}| cut -d: -f1) --color=always --ext-diff $forgit_fancy"
  git stash list |
    __forgit_fzf +s +m -0 --tiebreak=index \
    --bind="enter:execute($cmd |LESS='-R' less)" \
    --preview="$cmd"
}

# git ignore generator
export FORGIT_GI_CACHE=~/.gicache
export FORGIT_GI_INDEX=${FORGIT_GI_CACHE}/.index
__forgit_ignore() {
    [ -f $FORGIT_GI_INDEX ] || __forgit_ignore_update
    local preview="echo {} |awk '{print \$2}' |xargs -I% bash -c 'cat $FORGIT_GI_CACHE/% 2>/dev/null || (curl -sL https://www.gitignore.io/api/% |tee $FORGIT_GI_CACHE/%)'"
    ${IFS+"false"} && unset oldifs || oldifs="$IFS" #store IFS
    IFS=$'\n'
    [[ $# -gt 0 ]] && args=($@) || args=($(cat $FORGIT_GI_INDEX |nl -nrn -w4 -s'  ' |__forgit_fzf -m --preview="$preview" --preview-window="right:70%" |awk '{print $2}'))
    ${oldifs+"false"} && unset IFS || IFS="$oldifs" # restore IFS
    test -z "$args" && return 1
    local options=(
    '(1) Output to stdout'
    '(2) Append to .gitignore'
    '(3) Overwrite .gitignore')
    opt=$(printf '%s\n' "${options[@]}" |__forgit_fzf +m |awk '{print $1}')
    case "$opt" in
        '(1)' )
            __forgit_ignore_get ${args[@]}
            ;;
        '(2)' )
            __forgit_ignore_get ${args[@]} >> .gitignore
            ;;
        '(3)' )
            __forgit_ignore_get ${args[@]} > .gitignore
            ;;
    esac
}

__forgit_ignore_update() {
  mkdir -p $FORGIT_GI_CACHE
  curl -sL https://www.gitignore.io/api/list |tr ',' '\n' > $FORGIT_GI_INDEX
}
__forgit_ignore_get() {
    mkdir -p $FORGIT_GI_CACHE
    echo $@ |xargs -I{} bash -c "cat $FORGIT_GI_CACHE/{} 2>/dev/null || (curl -sL https://www.gitignore.io/api/{} |tee $FORGIT_GI_CACHE/{})"
}
__forgit_ignore_clean() {
    [[ -d $FORGIT_GI_CACHE ]] && rm -rf $FORGIT_GI_CACHE
}

fzf-git() {
cat <<EOC
  fga:   add
  fgu:   unstage
  fgl:   log
  fgd:   diff
  fgr:   restore
  fgss:  show stash

  fgcob: checkout git branch/tag
  fgco:  checkout git commit
  fgh:   get git commit sha
EOC
}

# add aliases
if [[ -z "$FORGIT_NO_ALIASES" ]]; then
  alias ${forgit_add:-fga}=__forgit_add
  alias ${forgit_log:-fgl}=__forgit_log
  alias ${forgit_diff:-fgd}=__forgit_diff
  #alias ${forgit_ignore:-fgi}=__forgit_ignore
  alias ${forgit_restore:-fgr}=__forgit_restore
  alias ${forgit_unstage:-fgu}=__forgit_unstage
  #alias ${forgit_clean:-fgc}=__forgit_clean
  alias ${forgit_stash_show:-fgss}=__forgit_stash_show
fi

