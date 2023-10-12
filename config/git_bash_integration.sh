
. /usr/share/bash-completion/completions/git
__git_complete git-stat-color _git_diff

: ${GIT_PROMPT_MASTER:='master'}
: ${MAX_DISTANCE_TO_ORGIN_MASTER:=10}

# environment variable MINI_GIT has some control over the prompt. when set, some elements are smaller; IE: unstaged. To make it work with tmux status, set MINI_GIT with the set_mini_git function

vg() { git_files="$(git -c color.status=always s | fzf -m --ansi | cut -c4-)" ; [[ "$git_files" ]] && v $git_files ; }

git_mini_prompt()
{
mkdir -p ~/.tmux/plugins/tmuxake/pids/$$

cat << EOV > ~/.tmux/plugins/tmuxake/pids/$$/MINI_GIT
$1
EOV

export MINI_GIT="$1"
}

git_prompt() 
{
if (( NO_FULL_GIT )) ; then
	git_reduced_prompt
else
	git_full_prompt
fi
}


git_full_prompt() 
{
if $(git rev-parse 2> /dev/null) ; then 

	stashes=$(git stash list | wc -l)
	if [ $stashes != '0' ] ; then stashes=" ${stashes}s" ; else stashes='' ; fi

	staged=$(git diff --shortstat --cached| perl -pe 's/^ // ; s/ files? changed,/f/ ; s/ insertions?\(\+\),?/+/; s/ deletions?\(-\)/-/')
	if [[ -n $staged ]] ; then staged=" {$staged}" ; fi

	if (( $MINI_GIT )) ; then
		unstaged=$(git diff --shortstat | perl -pe 's/^ // ; s/ files? changed.*/f/')
	else
		unstaged=$(git diff --shortstat | perl -pe 's/^ // ; s/ files? changed,/f/ ; s/ insertions?\(\+\),?/+/; s/ deletions?\(-\)/-/')
	fi

	if [[ -n $unstaged ]] ; then unstaged=" $unstaged" ; fi

	untracked=$(git status -s 2> /dev/null | grep '??' | wc -l )
	if [ $untracked != '0' ] ; then untracked=" ${untracked}u" ; else untracked='' ; fi
	
	branches=$(git branch 2> /dev/null | wc -l) 
	if [ $branches -ne 0 ] ; then

		if ! git branch 2> /dev/null | grep -q "$GIT_PROMPT_MASTER" ; then
			branch=$(git_pwb) 
			GIT_PROMPT_MASTER="$branch" 
		fi

		if [ $branches -eq 1 ] ; then 
			branches=''
		elif [[ $branches -eq 2 ]] && git branch | grep -q -s -P '^(\*| ) master$' && git branch | grep -q -s -P '^(\*| ) release$' ; then 
			branches=''  
		else 
			branches="${branches}b"
		fi

		branch=$(git_pwb) 
		branch_display="$branch"
		if [[ $branch == 'master' ]] ; then branch_display='■' ; fi
		if (( $MINI_GIT )) ; then branch_display='' ; fi


		origin_branch=$(xgit_remote_who_tracks_this_branch)
		origin=${origin_branch/\/$branch//}
		origin=${origin%/}

		if [ -z "$origin_branch" ] ; then on_remote='L:' ; fi

		master=$(git log $GIT_PROMPT_MASTER..HEAD --pretty=oneline | wc -l) 
		if [ $master -ne 0 ] ; then 
			master=" +m$master"
		else
			master=$(git log HEAD..$GIT_PROMPT_MASTER --pretty=oneline | wc -l) 
			if [ $master -ne 0 ] ; then 
				master=" -m$master"
			else
				 master=''
			fi
		fi

		git branch -r --no-color 2> /dev/null | grep -q "$origin/"
		if [ "$on_remote" != "L:" ] && [ $? -eq 0 ] ; then 

			origin_master=$(git log $origin/$GIT_PROMPT_MASTER..HEAD --pretty=oneline | wc -l) 
			if [ $origin_master -ne 0 ] ; then 
				origin_master=" +om$origin_master" 
			else 
				origin_master=$(git log HEAD..$origin/$GIT_PROMPT_MASTER --pretty=oneline | wc -l) 
				if [ $origin_master -ne 0 ] ; then 
					origin_master=" -om$origin_master"
				else 
					origin_master=''
				fi
			fi

			if [ "$branch" != "$GIT_PROMPT_MASTER" ] ; then
				origin_branch_distance=$(git log $origin/$branch..HEAD --pretty=oneline | wc -l)
				if [ $origin_branch_distance -ne 0 ] ; then
					origin_branch_distance=" +$origin_branch:"
				else 
					origin_branch_distance=$(git log HEAD..$origin/$branch --pretty=oneline | wc -l)
					if [ $origin_branch_distance -ne 0 ] ; then 
						origin_branch_distance=" -$origin_branch_distance:"
					else
						 origin_branch_distance=''
					fi
				fi
			fi

			if git branch -r --no-color | cut -f 3 -d ' ' | grep -q 'origin/master' &&\
			   [ "$GIT_PROMPT_MASTER" != "master" ] && [ "$branch" != "master" ] ; then
				origin_master_fixed=$(git log $origin/master..HEAD --pretty=oneline | wc -l 2>/dev/null) 
				
				if [ $origin_master_fixed -ne 0 ] && [ $origin_master_fixed -gt $MAX_DISTANCE_TO_ORGIN_MASTER ] ; then 
					origin_master_fixed=" +oM$origin_master_fixed" 
				else 
					origin_master_fixed=$(git log HEAD..$origin/master --pretty=oneline | wc -l 2>/dev/null) 
					
					if [ $origin_master_fixed -ne 0 ] && [ $origin_master_fixed -gt $MAX_DISTANCE_TO_ORGIN_MASTER ] ; then 
						origin_master_fixed=" -oM$origin_master_fixed" 
					else 
						origin_master_fixed=''
					fi
				fi
			fi
		fi
	else
		branches='empty repository'
	fi

	merging=$([[ -e .git/MERGE_HEAD ]] && echo " Merging ")
	rebasing=$([[ -d .git/rebase-apply ]] && echo " Rebasing")

	# build up the prompt with spacing the elements that are not null

	prompt=''

	if [[ -n  "$master$origin_master$origin_master_fixed" ]] ; then  prompt="$master$origin_master$origin_master_fixed " ;	fi

	if [[ -n  "$branches$stashes" ]] ; then prompt+="[$branches$stashes] " ; fi

	git_state="$origin_branch_distance$on_remote$branch_display$staged$unstaged$untracked$merging$rebasing"
	if [[ -n  $git_state ]] ; then prompt+="$git_state " ; fi

	echo "${prompt## }"
fi
} ;


git_reduced_prompt() 
{
if $(git rev-parse 2> /dev/null) ; then 
	unstaged=$(git diff --shortstat | perl -pe 's/^ // ; s/ files? changed.*/f/')
	if [[ -n  $unstaged ]] ; then prompt="$unstaged " ; fi

	echo "$prompt"
fi
} ;

gclo='git clone' ;
gclo1='git clone --depth=1'

gcl()
{
local dir="/tmp/$USER/gcl" ; mkdir -p "$dir" ; local clone_dir=$(mktemp -p "$dir")

git clone "$@" |& tee >(perl -ne "/^Cloning into '(.*)'...$/ && qx~echo \$1 > $clone_dir~") && cd $(<$clone_dir) 
}

alias gcl1='gcl --depth=1'
alias ga='git add'
alias gs='git s'
alias gs_no_untracked_files='git s -uno '
alias gc='git commit' ; __git_complete gc _git_commit
alias gl='gl10' ; __git_complete gl _git_log
alias gl0='git l' ; __git_complete gl _git_log
alias gla='gla10' ; __git_complete gl _git_log
alias gla0='git la' ; __git_complete gl _git_log
alias gls='git ls' ; __git_complete gl _git_log
alias glb='git lb' ; __git_complete gld _git_log
alias glba='git lba' ; __git_complete gld _git_log
alias gdo='git diff' ; __git_complete gdo _git_diff
alias gts='git-tree-status'
alias git_has='< <(git ls-files) grep'

gl10() { git --no-pager l -10 "$@" ; echo ; }
__git_complete gl _git_log

gla10() { git --no-pager la -10 "$@" ; echo ; }
__git_complete gla _git_log

git_ls_files() { git ls-tree -r --name-only ${1:-HEAD} | lscolors ; } ; __git_complete git_ls_files _git_branch
alias gls='git_ls_files' ; __git_complete gls _git_branch

gsv() 
{
files="$(git -c color.status=always status --short | fzf --ansi -m)"
[[ "$files" ]] && v $(echo "$files" | perl -ne 'chomp ; s/\e\[([0-9;]*)m//g ; s/\[K//g ; s/.{3}// ; print qq~$_ ~')
}

gd() { diff=`git diff --color $*` ; [[ "$diff" ]] && <<<"$diff" diff-so-fancy | /usr/bin/less -RFX --pattern '^(Date|added|deleted|modified): ' || true ; }
__git_complete gd _git_diff

git_less() { diff-so-fancy | less -RFX --pattern '^(Date|added|deleted|modified): ' ; }

git_diff_stash() { diff=`git diff --color stash@{0} $*` ; <<<"$diff" diff-so-fancy | less -RFX --pattern '^(Date|added|deleted|modified): ' ; }
__git_complete gd _git_diff


gvimdiff() 
{
git difftool -y -t vimdiff "$@"
}
__git_complete gvimdiff _git_diff


gdc() { tmux splitw -h -l 40% git commit -a ; gd ; }

alias gco='git checkout --quiet' ; __git_complete gco _git_checkout
alias gnb='git checkout -b' ; __git_complete gnb _git_branch
alias gm='git merge' ; __git_complete gm _git_merge
alias git_remove_from_index='git reset' ; __git_complete git_remove_from_index _git_rm

#alias gan='git annex'
#. /usr/share/bash-completion/completions/git-annex >/dev/null 2>&1 
#__git_complete gan _git-annex
#
#alias gans='git annex sync --content'

git_track_all_branches()
{
for branch in `git branch -a | grep remotes | grep -v HEAD | grep -v master `; do
	   git branch --track ${branch#remotes/origin/} $branch
	   done
}

git_update_remote()
{
git push -u origin $(git_pwb) 
}
__git_complete git_update_remote _git_branch
alias gup=git_update_remote

git_status_stat()
{

perl - <<'EOF' $*
#!/usr/env perl

use warnings ;
use strict ;

my ($max, @gss) = (-1) ;

for my $file_status ( `script --return -qfc "git status -uno --short"  /dev/null` )
        {
        chomp $file_status ;
        $file_status =~ s/\r$// ;

        my $file = (split '\s+', $file_status)[-1] ;

        if(-e $file)
		{
		$_ = `git diff --shortstat $file` ;
		chomp ;
		s/^.{16}// ;
		s/ insertions?\(\+\),?/+/;
		s/ deletions?\(-\)/-/;
		}
	else
		{
		my $lines = `git show HEAD:$file | wc -l` ;
		chomp $lines ;

		$_ = ' 0+ ' . $lines . '-' ;
		}

        push @gss, [$file_status, length $file, $_] ;

        $max = $max >= length $file ? $max : length $file ;
        }

for my $entry (sort { $b->[2] cmp $a->[2] } @gss)
        {
        printf "%s%s%s\n", $entry->[0], ' ' x ($max - $entry->[1]) , $entry->[2] ;
        }

EOF
 
}
alias gss=git_status_stat
  
git_remove_last_commit()
{
git reset --soft HEAD~
}

git_remove_last_commit_dont_keep_changes()
{
git reset --hard HEAD~
}

git_squash()
{
revisions=$1

if [ -n $revisions ] ; then
	if [ ! -z "${revisions##*[!0-9]*}" ] ; then
		git rebase -i HEAD~$revisions
	else
		git rebase -i $revisions
	fi
else
	echo "Usage:"
	echo "  gsquash number_of_revisions|branch_head"
fi
} ;
__git_complete gsquash _git_rebase
alias gsq=git_squash
__git_complete gsq _git_rebase

gcm() { git commit -m "$*" ; }
__git_complete gcam _git_commit

	
gca() { git commit -a "$@" ; }
__git_complete gcam _git_commit

gcam() { git commit -am "$*" ; }
__git_complete gcam _git_commit


gcamA() { git commit -a -t <(echo "ADDED: $*") ; }
__git_complete gcamA _git_commit

gcamF() { git commit -a -t <(echo "FIXED: $*") ; }
__git_complete gcamF _git_commit

gcamC() { git commit -a -t <(echo "CHANGED: $*") ; }
__git_complete gcamC _git_commit

gcama() { git commit -am "ADDED: $*" ; }
__git_complete gcama _git_commit

gcamf() { git commit -am "FIXED: $*" ; }
__git_complete gcamf _git_commit

gcamc() { git commit -am "CHANGED: $*" ; }
__git_complete gcamc _git_commit

gcamw() { git commit -am "WIP: $*" ; }
__git_complete gcamw _git_commit

gcaa() { git commit -a --amend ; }
__git_complete gcamc _git_commit

gcaaa() { git commit -a --amend --no-edit ; }
__git_complete gcamc _git_commit

git_rebase_interactive_fzf()
{
HASH=`git log $* --graph --color=always --pretty=format:'%C(yellow)%h %C(white bold)%s %C(blue bold)%d %C(black bold)(%ar, %an)%Creset' | \
	fzf --ansi | \
	perl -ne '/^.*?([0-9a-f]+).*$/ && print $1'` && \
		git rebase -i ${HASH}^ ;
}
alias gsq=git_rebase_interactive_fzf

git_pwb()
{
git rev-parse --abbrev-ref HEAD 2>/dev/null | grep -v HEAD
}

git_branch_erase()
{
git_remote_delete_branch $1
git branch -d $1
}
__git_complete git_branch_erase _git_branch

git_need_fetch()
{
# check with the remote repository if a branch needs to be fetched
perl -e 'for (`git ls-remote --heads 2>/dev/null`) {($c, $b) = split /\s+/ ; $b =~ s[refs/heads/][] ;print "Branch $b is newer on server than local copy. Use git fetch to sync.\n" if grep { /no such commit/ }  `git branch -r --contains $c 2>&1`}'
}

git_merge_status()
{
echo 'Merged:'
git branch -a -vv --merged $*

echo 'Not merged:'
git branch -a -vv --no-merged $*
}
__git_complete git_merge_status _git_branch

xgit_get_file()
{
REPO=$1
FILE=$2
REVISION=${3:-HEAD}
git archive --remote="$REPO" "$REVISION" "$FILE" | tar -xO  
}

xgit_show_deleted_files()
{
git log --diff-filter=D --summary
}

#xgit_remote_who_tracks_this_branch()
#{
##git status -sb
#git rev-parse --abbrev-ref $(git_pwb)@{u} 2>/dev/null
#}
#__git_complete xgit_remote_who_tracks_this_branch _git_rev_parse

git_remote_mirror_this_branch()
{
# tracked mirroring
git push origin $(git_pwb)
git branch -u origin/$(git_pwb)
}
__git_complete git_remote_mirror_this_branch _git_branch

xgit_remote_mirror_this_branch_untracked()
{
git push origin $(git_pwb)
}

xgit_remote_track_this_branch_on()
{
git branch -u origin/$1
}

xgit_remote_stop_tracking_this_branch()
{
#git branch --unset-upstream
git branch -d -r origin/$(git_pwb) 
}
__git_complete xgit_remote_stop_tracking_this_branch _git_branch

git_remote_delete_branch()
{
git push origin --delete $1
}
__git_complete git_remote_mirror_this_branch _git_push

git_xxx()
{
origin=$1
branch=$2

if [ -z $branch ] ; then
	if [ -z $origin ] ; then
		branch=$(git_pwb)
		origin=$(git remote)
	else
		branch=$origin
		origin=$(git remote)
	fi
	
fi

echo "$origin $branch"

git remote show $origin $branch
}

gcount()
{

# count how many commits contain a change to the given file (regex)

perl - <<'EOF' $*
#!/usr/env perl

use strict ;
use warnings ;
use Getopt::Long ;

GetOptions
	(
	'a|all' => \(my $all=''),
	'r|range=s' => \(my $range=''),
	) or die "Accepted argument -a|all, r|range\n" ;
my $all_option = $all ? '--all' : '' ;

my $pattern = q{^$} ;
my $files = join(' ', @ARGV) ;
my @counts = `git log --pretty=format: --name-only $all_option $range -- $files | grep -v -P $pattern | sort | uniq -c | sort -rg` ;

print @counts ;

exit ! @counts ;
EOF
}

alias gbd='git branch'
__git_complete gbd _git_branch

alias gb='gb_fancy refs/heads'
__git_complete gb _git_branch

alias gba='gb_fancy'
__git_complete gba _git_branch

alias gbau='git fetch --all --prune >/dev/null ; gb_fancy'
__git_complete gbau _git_branch

gb_fancy()
{
#https://stackoverflow.com/questions/5188320/how-can-i-get-a-list-of-git-branches-ordered-by-most-recent-commit
git for-each-ref | rg -q 'origin/master' && from=origin/master || from=origin/main

git for-each-ref \
	--sort=-committerdate \
	--format='%(HEAD)%(refname:short)|%(committerdate:relative)|%(objectname)|%(subject)'\
	--count=${gb_count:-20} \
	$@ \
| while read line 
	do 
		branch=$(echo "$line" | awk 'BEGIN { FS = "|" } { print $1 }' | tr -d '*')
		ahead=$(git rev-list --count "${gb_refbranch:-$from}..${branch}")
		behind=$(git rev-list --count "${branch}..${gb_refbranch:-$from}")
		echo "ª$aheadᵇ$behind|$line"
	done \
| piper 'ª\d+' grey8 'ᵇ\d+' grey8 '\*\w+' rgb030 '\w+/\w+' red '[0-9]+ .* ago' 'dark blue' '[0-9a-f]{40}' {rgb410}'substr({}, 0, 6)' '.*' grey17\
| column -ts'|'
}

#alias gba='gb -a'
#gb()
#{
#perl - <<'EOF' $*
##!/usr/env perl

#use strict ;
#use warnings ;
#use Term::ANSIColor ;

#my $SHA = qr/[0-9a-f]{5,40}/ ;

#my @branches = `git branch -vv --color @ARGV` ;

#for (@branches)
#	{
#	my ($branch, $sha, $subject) = ('?', '?', '?') ;

#	if (($branch, $sha, $subject) = /^(.*?)($SHA)(.*)$/)
#		{
#		}
#	elsif(($branch, $sha) = /^(.*?)\s+(->.*)$/)
#		{
#		$sha = color('blue') . $sha ;
#		$subject = '' ;
#		}
#	else
#		{
#		warn "Can't parse '$_'\n" ;
#		}

#	print $branch . color('yellow') . $sha . color('reset') . $subject . "\n" ;
#	}
#EOF
#}
#__git_complete gb _git_branch

gbu() { git push --set-upstream ${1:-origin} ${2:-$(git_pwb)} ; }
__git_complete gbu _git_branch

gbr()
{
git remote -v show  $(git remote)
}
__git_complete gbr _git_remote

gbrg() { git checkout --track "$@" ; }
__git_complete gbrg _git_checkout 

# gbd() { git branch -dr origin/"$1" && git branch -d "$1" || echo "You need to force removal of local branch" && false ; }
# __git_complete gbd _git_branch

gbDf() { git branch -Dr origin/"$1" 2>&- ; git branch -D "$1" ; }
__git_complete gbDf _git_branch

gbD() { git branch -Dr origin/"$1" && git branch -D "$1" || echo "You need to force removal of local branch" && false ; }
__git_complete gbD _git_branch

gff() { git rev-list $* ; }
__git_complete gff _git_log

git_find_file()
{
perl - <<'EOF' $*
#!/usr/env perl

use strict ;
use warnings ;
use Term::ANSIColor ;
use Getopt::Long ;

GetOptions
	(
	'a|all' => \(my $all=''),
	'f|filter=s' => \(my $filter='AMDR'),
	'r|range=s' => \(my $range=''),
	'p' => \(my $patch),
	) or die "Accepted argument -f|filter, -r|range, -a|all, -p\n" ;
my $all_option = $all ? '--all' : '';

my $SHA = qr/[0-9a-f]{5,40}/ ;

my $files_to_search = join ' ', @ARGV ;
my $matched ;

my @commits_statuses = `git log --name-status --diff-filter=$filter --pretty="%h %s" $range $all_option -- $files_to_search` ;
chomp @commits_statuses ;

while(@commits_statuses)
	{
	$matched++ ;

	my ($commit_subject, undef, $status_name) = splice @commits_statuses, 0, 3 ;
	my ($commit, $subject) = $commit_subject =~ /^($SHA) (.*)/ ;

	my @containing_branches = `git branch --contains $commit` ;
	@containing_branches = map { chomp ; s[^\s+][] ; s[\s+][] ; $_ } @containing_branches ;

	my $containing_branches = '[' . join(', ', @containing_branches) . ']' ;
	
	print color('yellow') . $commit . ' ' . color('bold blue') . $containing_branches . color('reset') . ' ' . $subject . "\n" ;
	print "$status_name\n" ; 
	#my ($status, $file) = (substr($status_name, 0, 1), (substr($status_name, 1)) ;
	
	while(@commits_statuses && ($commits_statuses[0] !~ /$SHA/))
		{ 
		my $status_name = shift @commits_statuses ;
		print "$status_name\n" ;
		#my ($status, $file) = (substr($status_name, 0, 1), (substr($status_name, 1)) ;
		}

	if($patch)
		{
		print `git log $commit -1 --color --pretty="" -p -- $files_to_search`
		}

	#push @files, [ qr/$commit/ => $file => $status => '[' . join(', ', @containing_branches) . ']' ] ;
	}

exit !$matched ;

EOF
}
__git_complete git_find_file _git_log

git_graph_find_file()
{
perl - <<'EOF' $*
#!/usr/env perl

use strict ;
use warnings ;
use Data::TreeDumper ;

use Getopt::Long ;

GetOptions
	(
	'c|compact' => \(my $compact=0),
	'a|all' => \(my $all='')
	) or die "Accepted argument -c|compact, -a|all\n";
my $all_option = $all ? '--all' : '';

my $SHA = qr/[0-9a-f]{5,40}/ ;

print DumpTree \@ARGV ;

my @files ;
for my $argument (@ARGV)
	{
	my ($file, $filter) = $argument =~ /^([^:]+)(?::([AMDRCRTUXB]+))?$/ ;

	next unless defined $file ;
	$filter ||= 'AMDR' ;

	my @commits_statuses = `git log $all_option --name-status --diff-filter=$filter --pretty="%h" -- $file` ;
	chomp @commits_statuses ;

	while(@commits_statuses)
		{
		my ($commit, undef, $status_name) = splice @commits_statuses, 0, 3 ;
		my ($status, $file) = (substr($status_name, 0, 1), substr($status_name, 1)) ;
		$file =~ s/^\s+// ; $file =~ s/\s+$// ;

		my $files_found = "$status:$file" ;

		while(@commits_statuses && ($commits_statuses[0] !~ /$SHA/))
			{ 
			my $status_name = shift @commits_statuses ;
			my ($status, $file) = (substr($status_name, 0, 1), substr($status_name, 1)) ;
			$file =~ s/^\s+// ; $file =~ s/\s+$// ;
			$files_found .= ", $status:$file" ;
			}

		push @files, [ qr/$commit/ => $files_found ] ;
		}
	}

my @log = `git log $all_option --color --graph --pretty=format:'%C(yellow)%h %C(white bold)%s %C(blue bold){{branch:%d}} %C(black bold)(%ar, %an)%C(red)'` ;

my $matched = 0 ;

for my $log_line (@log)
	{
	chomp $log_line ;

	if(my ($sha) = $log_line =~ /($SHA)/)
		{
		my $branch = $log_line =~ s/{{branch:([^}]+)}}/$1/ ;

		if(! $branch)
			{
			$log_line =~ s/{{branch:}}// ;
			}

		my @matches ;
		for my $file (@files)
			{
			push @matches, $file->[1] if($log_line =~ /$file->[0]/) ;
			}
		
		if(@matches)
			{
			$matched++ ;
			print "$log_line <== " . join(', ', @matches) . "\n" ;
			}
		else
			{
			print "$log_line\n" if $branch || (! $compact) ;
			}
			
		}
	else
		{
		print "$log_line\n" ; # no SHA, just glyphs
		}
	}

print "\n" ;

exit !$matched ;


EOF

}
#__git_complete git_log_graph_find _git_branch

git_graph_find_commit()
{
#finds commits and displays them in a graph

perl - <<'EOF' $*
#!/usr/env perl

use strict ;
use warnings ;
use Data::TreeDumper ;

use Getopt::Long ;

GetOptions
	(
	'c|compact' => \(my $compact=0),
	'a|all' => \(my $all='')
	) or die "Accepted argument -c|compact, -a|all\n";
my $all_option = $all ? '--all' : '';

my $SHA = qr/[0-9a-f]{5,40}/ ;

my @log = `git log $all_option --color --graph --pretty=format:'%C(yellow)%h %C(white bold)%s %C(blue bold){{branch:%d}} %C(black bold)(%ar, %an)%C(red)'` ;

my $matched = 0 ;

for my $log_line (@log)
	{
	chomp $log_line ;

	if(my ($sha) = $log_line =~ /($SHA)/)
		{
		my $branch = $log_line =~ s/{{branch:([^}]+)}}/$1/ ;

		if(! $branch)
			{
			$log_line =~ s/{{branch:}}// ;
			}

		my @matches ;
		my $regex = join('|', @ARGV) ;
		push @matches, '' if $sha =~ /$regex/ ;

		if(@matches)
			{
			$matched++ ;
			print "$log_line <== " . join(', ', @matches) . "\n" ;
			}
		else
			{
			print "$log_line\n" if $branch || (! $compact) ;
			}
			
		}
	else
		{
		print "$log_line\n" ; # no SHA, just glyphs
		}
	}

print "\n" ;

exit !$matched ;

EOF

}
#__git_complete git_graph_find_commit _git_branch

git_checkout_branch_in()
{
branch=$1
directory=$2

: ${branch:='master'}
: ${directory:='/tmp/git_checkout_branch_in'}

branch_commit=$(git log -n 1 --pretty="%h" $branch -- 2>/dev/null)
 
if [ $? -ne 0 ] ; then
	echo Error: unknown branch $branch
	return 1
else
	path="$directory/branch_$branch@$branch_commit"

	if [ -d "$path" ]; then
		rm -rf "$path"
	fi

	mkdir -p $path
	git archive $branch -- | tar -xC $path
fi

echo $path
}
__git_complete git_checkout_branch_in _git_branch

gdiffd()
{
revision=$1
compare_to=$2
diff_tool=${DDIFF_TOOL:-meld}

if [ -z $revision ] ; then revision='HEAD' ; fi

if [ $revision = '--help' ] ; then
	echo "Usage:"
	echo "  gdiffd                     diffs HEAD and current directory"
	echo "  gdiffd revision            diffs revision and current directory"
	echo "  gdiffd revision revision2  diffs revision and revision2"
	echo ""
	echo "temporary directories are not deleted"
else
	repo=$(basename `git rev-parse --show-toplevel`)
	path=$(git_checkout_branch_in $revision "/tmp/gdiffd/$repo")
	
	if [ $? -ne 0 ] ; then
		echo $path
	else
		if [ -z $compare_to ] ; then
			compare_to=`pwd`

			$diff_tool $path $compare_to
		else
			compare_to=$(git_checkout_branch_in $compare_to "/tmp/gdiffd/$repo")
		
			if [ $? -ne 0 ] ; then
				echo $compare_to
			else
				$diff_tool $path $compare_to
			fi
		fi
			
		gss 
		echo gdiffd: $path $compare_to
	fi

fi
} ;
__git_complete gdiffd _git_show

gdiff()
{
file=$1
revision=$2
diff_tool=${FDIFF_TOOL:-meld}

if [ ! -z $file ] ; then
	if [ -z $revision ] ; then revision='HEAD' ; fi

	diff -q  <(git show $revision:$file) $file &>/dev/null

	if [ $? -ne 0 ] ; then
		$diff_tool <(git show $revision:$file) $file
	else
		echo "files are identical"
	fi
else
	echo "Usage:"
	echo "  gdiff file             diff file and HEAD:file"
	echo "  gdiff file revision    diff file and revision:file"
fi
} ;
__git_complete gdiff _git_show


git_grep()
{
echo "git grep --color --line-number -P <search> \$(git rev-list HEAD) -- <path>"
history -s "git grep --color --line-number -P <search> \$(git rev-list HEAD) -- <path> | git_grep_reformat"

echo "git grep --line-number -e dk -e dz --all-match \$(git rev-list --all) -- <path>"
echo "git grep <search> \$(git rev-list <rev1>..<rev2>)"
echo "git grep -C 3 -v --count --max-depth 2"
echo "git log -S<search> --since=2009.1.1 --until=2010.1.1 -- path_containing_change"
}

git_grep_reformat()
{

perl <(cat <<'EOF'
#!/usr/env perl

use strict ; use warnings ;
use Term::ANSIColor 2.01 qw(color colorstrip) ; 

my $SHA = qr/[0-9a-f]{5,40}/ ;

my $previous_commit  = '' ;
my $previous_file  = '' ;

my $break = 0 ;
my $matched = 0 ;

while(my $line = <STDIN>)
	{
	$break++ if $line =~ /^$/ ;
	next if $line =~ /^$/ ;
	next if $line =~ /\x1b\x5b\x33\x36\x6d--/ ;

	$matched++ ;

	my ($commit, $file, $line_number, $elements) ;

	if($line =~ /^Binary file /)
		{
		($commit, $file) = $line =~ /^Binary file ($SHA):(.+)$/ ;
		$elements = color('red') . 'Binary file' . color('reset') ;
		}
	else
		{
		# ($commit, $file, $elements) = $line =~ /^($SHA):([^:]+?)(?:\x1b\x5b\x33\x36\x6d(?:-|:)(.*))?$/ ;
		($commit, $file, $line_number, $elements) = $line =~ /($SHA):([^:]+:)([^:]+):(.*)$/ ;
		}

	$elements = '' unless defined $elements ;

	if($commit ne $previous_commit)
		{
		$previous_commit = $commit ;
		$previous_file = '' ;
		$break = 0 ;

		my @containing_branches = `git branch --contains $commit` ;
		@containing_branches = map { chomp ; s[^\s+][] ; s[\s+][] ; $_ } @containing_branches ;

		my $containing_branches = '[' . join(', ', @containing_branches) . ']' ;
		
		print color('yellow') . substr($commit, 0, 7) . color('bold blue') . $containing_branches . color('reset') . "\n" ;
		}

	if($file ne $previous_file)
		{
		print "\n" if $break ;
		$break = 0 ;

		$previous_file = $file ;
		print color('cyan') . "\t$file\n" . color('reset') ;
		}

	print color('magenta') ;
	printf "\t%8s ", colorstrip($line_number) ;
	print color('reset') ;
	print "$elements\n"
	}

exit ! $matched ;

EOF
)
 
}

git_list_files_in_commit()
{
git ls-tree --name-only -r $*
}
__git_complete git_list_files_in_commit  _git_ls_tree


git_show_parents()
{
# todo, make it work for n parents

perl - <<'EOF' $*
#!/usr/env perl

use strict ;
use warnings ;
use Term::ANSIColor ;

my $h_p1_p2 = `git log --pretty="%h %p" -n 1 @ARGV` ;

die $? if $? ;

my ($h, @p) = split /\s/, $h_p1_p2 ;

my $s = `git show --quiet --pretty=format:'%s (%an)' $h` ;

print color('yellow') . "$h" . color('reset') . " $s\n\n" ;

for(@p)
	{
	next unless defined $_ ;
	
	my $s = `git show --quiet --pretty=format:'%s (%an)' $_` ;

	print "\t" . color('yellow') . "$_" . color('reset') . " $s" . "\n\t" . color('blue bold') 
		. join("\t" . color('blue bold'), `git branch --contains $_`) . "\n" ;
	print color('reset') ;
	}

EOF
}
 
git_show_parents_compact()
{
git rev-list --parents -n 1 $*
}

git_show_children_compact()
{
git log --ancestry-path $*
}

git_show_children_graph()
{
git log --graph $* 
#git log f9073df0ccb^..master
}

commit()
{

perl - <<'EOF' $*
#!/usr/env perl

use strict ;
use warnings ;
use Term::ANSIColor ;
use Data::TreeDumper ;
use Getopt::Long ;

GetOptions
	(
	'a|all' => \(my $all = ''),
	'r|range=s' => \(my $range = ''),
	's|start_with' => \(my $start_with = 0),
	'm|message' => \(my $message = 0),
	) or die "Accepted argument -a|all, r|range\n" ;
my $all_option = $all ? '--all' : '' ;

my ($start, $sha) = ('HEAD', '') ;
if(@ARGV == 0)
	{
	($start, $sha) = ('HEAD', '.{7}') ;
	}
elsif(@ARGV == 1)
	{
	($sha) = @ARGV ;
	}
else
	{
	($start, $sha) = @ARGV ;
	}


my @commits = `git rev-list $start` ;
my $first_match ;
my ($pre_match, $match) ;

for(@commits)
	{
	chomp ;

	if(($match) = /(^$sha)/)
		{
		$first_match = $_ if ! defined $first_match ;
		chomp $first_match ;

		my $max_length = length($match) > 7 ? length($match) : 7 ;

		print color('bold yellow') . $match . color('reset') ;
		print color('yellow') . substr($_, length($match), 7 - length($match)) if length($match) < 7 ; 
		print color('reset') . substr($_, $max_length) ; 

		if($message)
			{
			my $message = `git log --pretty='%s' $_ -1` ;
			chomp $message ;

			print "    $message" ;
			}

		print "\n" ;
		}
	elsif((! $start_with) && (($pre_match, $match) = /(.*)($sha)/))
		{
		print $pre_match
			. color('yellow bold') . $match 
			. color('reset') . substr($_, length($pre_match) + length($match)) 
			. "\n" ; 
		}
	}


print color('yellow') . "\n$first_match\n" if defined $first_match ;

`echo -n $first_match | xclip -i -sel clipboard | true` if defined $first_match ;

EOF
} 


git_perl()
{

perl <(cat <<'EOF'
#!/usr/env perl

use strict ;
use warnings ;
use Term::ANSIColor ;
use Data::TreeDumper ;
use Getopt::Long ;

GetOptions
	(
	'a|all' => \(my $all=''),
	'r|range=s' => \(my $range=''),
	) or die "Accepted argument -a|all, r|range\n" ;
my $all_option = $all ? '--all' : '' ;

EOF
)
}
 
git_perl()
{

perl - <<'EOF' $*
#!/usr/env perl

use strict ;
use warnings ;
use Term::ANSIColor ;
use Data::TreeDumper ;
use Getopt::Long ;

GetOptions
	(
	'a|all' => \(my $all=''),
	'r|range=s' => \(my $range=''),
	) or die "Accepted argument -a|all, r|range\n" ;
my $all_option = $all ? '--all' : '' ;

EOF
 
}

github_create_repo()
{
repo_name=$1
test -z $repo_name && echo "Repo name required." 1>&2 && exit 1

curl -u 'nkh' https://api.github.com/user/repos -d "{\"name\":\"$repo_name\"}"
git init
git remote add origin "https://github.com/nkh/$repo_name.git"
git push --set-upstream origin master
} 

git_list_changes_by_author()
{
git lngnc --name-only --author "$1" | sed '/^$/d'
}


git_list_changed_files_by_author()
{
git lngnc --name-only --author "$1" | sed '/^$/d' | rg -v -- '-->' | sort -u
}

# vim: set ft=bash:

