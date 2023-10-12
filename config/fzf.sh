
export FZF_DEFAULT_OPTS="--cycle --reverse --inline-info --color='hl:106'"
export FZF_PREVIEW_COMMAND="tvcat {}"

#history via fzf
#source ~/nadim/bin/ehc

source $META_HOME/devel/fzf-marks/fzf-marks.plugin.bash

# use what fzf comes with
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# export FZF_PREVIEW_COMMAND="tvcat {} 2>/dev/null | head -20"

# from fzf-extra 

# fgcob - checkout git branch/tag
fgco() {
  local tags
  local branches
  local target

  tags="$(
    git tag \
      | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}'
  )" || return

  branches="$(
    git branch --all \
      | grep -v HEAD \
      | sed 's/.* //' \
      | sed 's#remotes/[^/]*/##' \
      | sort -u \
      | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}'
  )" || return

  target="$(
    printf '%s\n%s' "$tags" "$branches" \
      | fzf-tmux \
          -l40 \
          -- \
          --no-hscroll \
          --ansi \
          +m \
          -d '\t' \
          -n 2 \
          -1 \
          -q "$*"
  )" || return

  git checkout "$(echo "$target" | awk '{print $2}')"
}

# fgco - checkout git commit
fgcoc() {
  local commits
  local commit

  # commits="$(
  #   git log --pretty=oneline --abbrev-commit --reverse
  # )" || return

  # commit="$(
  #   echo "$commits" \
  #     | fzf --ansi --tac +s +m -e
  # )" || return

  # git checkout "$(echo "$commit" | sed "s/ .*//")"

  commits="$(git log --all --graph --color --pretty=format:'%C(yellow)%h %C(white bold)%s %C(blue bold)%d %C(black bold)(%ar, %an)%Creset')" || return
  commit="$(echo "$commits" | fzf --ansi +s +m -e  )" || return
  git checkout $(perl -e '$ARGV[0] =~ /\b([0-9a-f]{5,40})\b/ ; print $1' "$commit")
}

# fgh - get git commit sha
# example usage: git rebase -i "$(fgh)"
fgh() {
  local commits
  local commit

  commits="$(
    git log "$@" \
      --pretty=format:'%C(yellow)%h %C(white bold)%s %C(blue bold)%d %C(black bold)(%ar, %an)%Creset' \
      --color=always \
      --reverse 
  )" || return

  commit="$(
    echo "$commits" \
      | fzf \
          --tac \
          +s \
          +m \
          -e \
          --ansi \
          --reverse
  )" || return

  echo -n "$(echo "$commit" | sed "s/ .*//")"
}
export -f fgh

# fgh - get git commit sha
# example usage: git rebase -i "$(fgh)"
fgha() {
  local commits
  local commit

  commits="$(
    git log --all "$@" \
      --pretty=format:'%C(yellow)%h %C(white bold)%s %C(blue bold)%d %C(black bold)(%ar, %an)%Creset' \
      --color=always \
      --reverse 
  )" || return

  commit="$(
    echo "$commits" \
      | fzf \
          --tac \
          +s \
          +m \
          -e \
          --ansi \
          --reverse
  )" || return

  echo -n "$(echo "$commit" | sed "s/ .*//")"
}
export -f fgh

# fstash - easier way to deal with stashes
# type fstash to get a list of your stashes
# enter shows you the contents of the stash
# ctrl-d shows a diff of the stash against your current HEAD
# ctrl-b checks the stash out as a branch, for easier merging
fgstash() {
  local out
  local q
  local k
  local sha

  while out="$(
    git stash list --pretty='%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs' \
      | fzf \
          --ansi \
          --no-sort \
          --query="$q" \
          --print-query \
          --expect=ctrl-d,ctrl-b
  )"; do
    mapfile -t out <<< "$out"
    q="${out[0]}"
    k="${out[1]}"
    sha="${out[-1]}"
    sha="${sha%% *}"
    [[ -z "$sha" ]] && continue
    if [[ "$k" == 'ctrl-d' ]]; then
      git diff "$sha"
    elif [[ "$k" == 'ctrl-b' ]]; then
      git stash branch "stash-$sha" "$sha"
      break
    else
      git stash show -p "$sha"
    fi
  done
}

# fzf-kill - kill process
fzf-kill() {
  local pid

  pid="$(
    ps -ef \
      | sed 1d \
      | fzf -m \
      | awk '{print $2}'
  )" || return

  kill -"${1:-9}" "$pid"
}



# fzf-tmux-pane - switch pane (@george-b)
fzf-tmux-pane() {
  local panes
  local current_window
  local current_pane
  local target
  local target_window
  local target_pane

  panes="$(
    tmux list-panes \
      -s \
      -F '#I:#P - #{pane_current_path} #{pane_current_command}'
  )"
  current_pane="$(tmux display-message -p '#I:#P')"
  current_window="$(tmux display-message -p '#I')"

  target="$(
    echo "$panes" \
      | grep -v "$current_pane" \
      | fzf +m --reverse
  )" || return

  target_window="$(
    echo "$target" \
      | awk 'BEGIN{FS=":|-"} {print$1}'
  )"

  target_pane="$(
    echo "$target" \
      | awk 'BEGIN{FS=":|-"} {print$2}' \
      | cut -c 1
  )"

  if [[ "$current_window" -eq "$target_window" ]]; then
    tmux select-pane -t "$target_window.$target_pane"
  else
    tmux select-pane -t "$target_window.$target_pane" \
      && tmux select-window -t "$target_window"
  fi
}

