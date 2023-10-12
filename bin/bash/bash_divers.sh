
br() { perl -E 'say q~-~ x ($ARGV[0] || 79)' "$1" ; }

i() { sudo apt install "$@" && echo "$@" >> ~/tom/config/apt_get_install  ; }
complete -F _apt i

alias is="fzf_apt_search"
complete -F _apt is

frequency() { cat "$@"| tr ' ' $'\n' | sort | uniq -c | sort -nr | less ; }

fspeak()
{
#todo: make it speak pipelines

voice="(voice_cmu_us_slt_arctic_hts)"

say_text="(SayText \"""$@""\")"

printf "$command1 "
/usr/bin/time -f '%E'  festival -b $voice "$say_text"
}

man_perl_match()
{
man "$1" | perl -00ne '$l//=1 ; print "\@$.-$l\n$_\n\n" if /'"$2"'/i; $l += $_=~tr/\n/\n/; $l++' | h "$2" | less -R +/"\@"
}
complete -F _man man_perl_match

alias man_grep=man_perl_match
complete -F _man man_grep

function fman()
{
man -k . | \
	fzf -q "$1" --prompt='man> '  \
	--preview $'echo {} | tr -d \'()\' | awk \'{printf "%s ", $2} {print $1}\' | xargs -r man' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' \
	| xargs -r man
}

headand() { IFS= read -r header ; printf '%s\n' "$header" ; "$@" ; }
headtee() { IFS= read -r header ; echo "$header" >/dev/tty ; cat ; }

shell-expand () { printf "%s\n" "$@" ; }
shell-expand-colored () { printf "%s\x1b[30;100m \x1b[0m\n" "$@" ; }

shortest () { perl -e '@K=sort{length($a) <=> length($b)}<>; print grep {length($_)==length($K[0])}@K;' ; }
longest () { perl -e '@K=sort{length($a) <=> length($b)}<>; print grep {length($_)==length($K[-1])}@K;' ; }
 
pcol () { perl -ae 'BEGIN{@f=@ARGV; @ARGV=()} chomp @F[-1]; $.==1 and @n=@F; @v{@n}=@F; print join(" ", map { @v{$_} // "#"} @f), "\n"' "$@" ; }
#< xxx pcol col1 'X' col2

pcoli () { perl -ae 'BEGIN{@f=@ARGV; @ARGV=()} chomp @F[-1]; print join(" ", map{ /[^[:digit:]]/?eval("\"$_\""):(@F[$_] // "#") } @f), "\n"' "$@" ; }
#<xxx pcoli 0 - 1

pcolc () { perl -ae 'print scalar(@F) . "\n"' $@ ; }

pchari () { perl -F'' -ae 'BEGIN{@f=@ARGV; @ARGV=()} chomp @F[-1]; print( /[^[:digit:]]/?eval("\"$_\""):(@F[$_] // "#")) for @f; print "\n"' "$@" ; }
#pchari 0 \* 1 \\t 1 \  2 - $(seq 4 -1 0)

last_command() { history | tail -n 2 | head -n 1 | perl -pe 's/^\s*[0-9]+\s*//' | tr -d '\n' ; }
export -f last_command

mkcd(){ mkdir -p $@ ; cd $@ ; }

cdt(){ mkdir -p /tmp/$USER ; t=$(mktemp -d /tmp/$USER/${1:-cdt}_XXXXX) ; cd $t ; p ; }

page() #uses vimcat
{
local prompt_size=1
local file=$(mktemp /tmp/page.XXXXXXXXX)

OPTIND=1

while getopts "p:" opt; do
	case $opt in
		p) prompt_size=$OPTARG ;;
		*) return 1;;
	esac
done

shift $((OPTIND-1))

/home/nadim/nadim/bin/vimcat > $file;

local lines=$(cat "$file" | wc -l);
if [[ -z $1 ]]; then
	local available=$((LINES - prompt_size));
	if (( available >= lines )); then
		/home/nadim/nadim/bin/vimcat $file;
	else
		l=$(( LINES - (prompt_size + 1) ));
		head -n $l "$file";
		echo "... ";
	fi;
else
	head -n "$1" "$file";
fi
}


# Add an "alert" alias for long running commands.  Use like so:  sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

transfer() 
{
if [ $# -eq 0 ]; then 
	echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md" 
	return 1 
fi 

tmpfile=$( mktemp -t transferXXX ); 

if tty -s ; then 
	basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g') 
	curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile 
else
	curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile 
fi

cat $tmpfile
rm -f $tmpfile
} 

faketty (){ script -qfc "$(printf "%q " "$@")" ; }
force_tty (){ script --return -qfc "$(printf "%q " "$@")" /dev/null ; }

untilfail (){ while $@; do :; done } 

open () 
{
xdg-open "$@">/dev/null 2>&1
}

atw()
{
args=("$@")
ack "${args[@]}" --color | plc -v | tw -v -no_tab -t "ack '$args' results:" ; sleep 0.03 ; tmux copy-mode
}

atw2()
{
args=("$@")
ack "${args[@]}" --color | plc -v | tw -v -no_tab -t "ack '$args' results:" ; sleep 0.03 ; tmux copy-mode
}

atw3()
{
args=("$@")
ack "${args[@]}" --color | plc -v | tw -v -no_tab
}

gtw ()
{
args=("$@")
grep "${args[@]}" * -r --color=always | plc -v | tw -v -no_tab -t "grep '$args' results:" ; sleep 0.03 ; tmux copy-mode
}

ppeep () 
{
local lines=${1:-0} ;
local timer=${2:-0} ;
local comment=$(echo -e "$@" | tr '\n' ' ') ; comment=${comment# }
perl -MTime::HiRes -n -e \
'
BEGIN	{
	sub sep 
		{
		my $comment = shift // q-- ;

		if('"$lines"')
			{
			$ppeep .= qq-\x1b[36m- . q[-] x 30 . " $comment\x1b[0m\n"
			}
		else
			{
			print STDERR qq-\x1b[36m- . q[-] x 30 . " $comment\x1b[0m\n"
			}
		}
	sep("'"$comment"'");
	}
$l++ ; 
chomp ;
$ppeep .= "\x1b[36m$_\x1b[33m[$l]\x1b[0m\n" if '"$lines"' ;
print "$_\n"; 
Time::HiRes::usleep('$timer');

END{print STDERR $ppeep}
'
}

psep () { comment=$(echo -e "$@" | tr '\n' ' ') ; comment=${comment# } ; perl -n -e "END {sub sep { print STDERR qq-\x1b[36m-. q[-] x 40 .qq-\x1b[0m\n-} sep(); if(q-$comment- ne q--){print STDERR qq-\x1b[36m$comment\x1b[0m\n-; sep()} } print" ; }

<<'EOC'
example pipe:
cat erica | sed -e '=' | sed 's/^/      /; N' | sed 'N ; s/^ *\(......\)\n/\1  /'

cat erica | ppeep 1 0 cat | sed -e '=' erica  | ppeep 1 1 sed = | sed 's/^/      /; N' | ppeep 1 2 sed N | sed 'N ; s/^ *\(......\)/\1  /' | ppeep 0 3 sed 's//'


ppeep cat erica | ppeep sed -e '=' | ppeep sed 's/^/      /; N' | ppeep sed 'N ; s/^ *\(......\)\n/\1  /'

Goals:

peep into one or more parts of the pipe
	get the inputs synchronized on the screen
		that need curses or something like it

	get the inputs in blocks
		only output is buffered for viewing. lines still output to next command
		need memory to do so as we must buffer all the input to display it then forward it
		need options to control the output, filtering (display, input, output), coloring, ...
		need options to slow down the output or control it with user input

add a comment after the last comment was run, show it before the output of the previous command

a clean inreface that requires little typing
	cat | do | somethin
	=> cat | ppeep | do | something | ppeep result
	=> ppeep cat | do | ppeep somethin
	=> ppeep cat | do | ppeep slow down control output options, write a comment after the processing | something 
	=> cat | ppeep do, show input and output and forward | do something
	

ppeep
	show comment first?
	show input? -> run command

	buffer input? buffer output?

	run command?
		show input interlaced with output? in  blocks?

	show output?
	show comments last?


interface
	separate command and options
		ppeep command command-option command-arguments # default ppeep usage, run, show input/output in block, buffer output
			equivlemt to: ppeep -exec command command-option command-arguments  


		ppeep -interlaced command command-option command-arguments # run, show blocks, buffer output


		ppeep -ppeep-option ppeep-argument -exec command 


use cases:

	command1 | command2 | command3
		want to understand command2:
			command1 | ppeep command2 | command3

			display comment at start (as soon as input is available)
			see command2 input
				color
				indentation
				filter what is seen
				control f(eeding)
				save the input to a file
				number lines

			control input
				higlight/stop at specific input line
				
			run command2
				feeding it all input
				interlacing input and output
				stepping input feed
					f(eed), feed one line
					5f, feed 5 lines
					af, all lines fed
					/regex, feed stop at matching line

			see command 2 output
			display comment at the end

	command1 | ppeep | ommand2 | command3
		no commands to run
		readd and display
		send to next commnad
		

	command1 | ppeep command2 | command3
	command1 | ppeep -i -o command2 | command3
		display start comment
		reads lines till eof
			display colored
		feeds them to command2
		reads lines from command2
			display colored
		writes lines in block

	ppeep -h command1 | command2 | command3
		displays start comment "ppeep: -h command" 
		doesn't read input
		colors output for viewing
		outputs lines as they come from command 1

	command1 | command2 | ppeep -t command3  (equivalent to -i +o)
		displays start comment "ppeep: -t command" 
		read input
		feeds them to command3
		reads lines from command3 (default time out)
		outputs lines as they come from command 1

	command1 | ppeep -i command2 | ppeep command3 (eq. -i -o) | command4
		display start comment
		reads all lines
			display colored
		feeds them to command2
		reads lines from command2 (default time out)
			display colored
		writes lines as they come
		display identical end comment

	command1 | ppeep -n N command2 | command3
		display start comment
		reads lines as they come in N blocks
			display colored
		feeds them to command2
		reads lines from command2 (default time out)
			display colored
		writes lines as they come


name
	pd, pipe debugger

options
	-show-process-start, off by default

	-full-command, show the command as expanded by the shell without limiting it to the
		terminals width

	-comment-start, override default message: command to be run
	-comment-end

	-h pipe start, no reading, display output, write output
	-t pipe end, read block, write output
	-i read input an display it
	-o display output, write output

	-ic input color
	-il number input lines
	-ii indent the input lines
	-if filer, display only matching line
		a perl script alt a regex in the form '/regex/'

	-o? same as above for output

	-delay
	-interactive-feed

	-interlace_io, default on
		feed lines and read output
		display output
		buffer the output, not send to next command before all input lines are processed

	-no-buffer-output, lines are send as soon as they arrive, ok if one ppeep only

multi level peep
	interactive?
		which pipe part is controlled?

	how many levels
		how do we get the information of how many ppeep are started?
			.ppeep_parent_PID containing PID
				check PID is running


		first, which one is tarted first?, ppeed writes PID
		
EOC


#align uniq -c to the left
alias uniqc='uniq -c | sed "s/^[ ]*//;s/ /\t/"'

cd_func ()
{
  local x2 the_new_dir adir index
  local -i cnt

  if [[ $1 ==  "--" ]]; then
    dirs -v
    return 0
  fi

  the_new_dir=$1
  [[ -z $1 ]] && the_new_dir=$HOME

  if [[ ${the_new_dir:0:1} == '-' ]]; then
    #
    # Extract dir N from dirs
    index=${the_new_dir:1}
    [[ -z $index ]] && index=1
    adir=$(dirs +$index)
    [[ -z $adir ]] && return 1
    the_new_dir=$adir
  fi

  #
  # '~' has to be substituted by ${HOME}
  [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

  #
  # Now change to the new dir and add to the top of the stack
  pushd "${the_new_dir}" > /dev/null
  [[ $? -ne 0 ]] && return 1
  the_new_dir=$(pwd)

  #
  # Trim down everything beyond 11th entry
  popd -n +11 2>/dev/null 1>/dev/null

  #
  # Remove any other occurence of this dir, skipping the top of the stack
  for ((cnt=1; cnt <= 10; cnt++)); do
    x2=$(dirs +${cnt} 2>/dev/null)
    [[ $? -ne 0 ]] && return 0
    [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
    if [[ "${x2}" == "${the_new_dir}" ]]; then
      popd -n +$cnt 2>/dev/null 1>/dev/null
      cnt=cnt-1
    fi
  done

  return 0
}

#alias cd=cd_func

if [[ $BASH_VERSION > "2.05a" ]]; then
  # ctrl+w shows the menu
  bind -x "\"\C-w\":cd_func -- ;"
fi

find-ignore() { find * "$@" -not -path "*/\.git/*" -not -path "*/_out_nadim/*" -not -path "*ftl/var/*" -not -path '*/_build/*' -not -path '*/*\.sw*' -not -path '*/blib/*' ; }
fic() { find-ignore "$@" | lscolors ; }

find-ignore-time() { find-ignore -mtime "$@" ; }
fitc() { find-ignore-time "$@" | lscolors ; } 
fit() { find-ignore-time "$@" ; } 

find-upwards()
{
# todo: option to continue searching
# todo: use regular expression or fuzzy expression  instead for single file name

local search ; [[ ${1:0:1} == "/" ]] && search="$1" || search="$PWD/$1" ; # work with full path for search

stat "$search" &>/dev/null && echo "$search" ||
	{
	local path="${search%/*}" file="${search##*/}" local parent_path="${path%/*}"
	[[ "$parent_path" ]] && upfind "$parent_path/$file"
	}
}

slow_find_dups () { find ./ -type f -print0 | xargs -0 -n1 md5sum | pv -s 10000 | sort -k 1,32 | uniq -w 32 -d --all-repeated=separate | sed -e 's/^[0-9a-f]*\ *//;' ; }

find_dups () { 

local guard="#rm "

local fmt='sub fmt { $p = 1024 ; for ("%0.f bytes", "%.2f Kb", "%.2f Mb" , "%.2f Gb") { return sprintf("$_", $_[0] * 1024 / $p) if $_[0] < $p ; $p <<= 10 }}'
local header="'# -------------- #'. ++\$c . ', duplicates: ' . \$#\$_ . ', ' . fmt((stat(\$_->[0]))[7]) . qq{\n}"

local sorting="for (@f) {\$s{\$_->[0]} = (stat(\$_->[0]))[7]} ; @f = sort { \$s{\$b->[0]} <=> \$s{\$a->[0]} } @f"

while :; do
	case $1 in
		-h|-\?|--help)
			echo 	"find_dups:"
			echo 	"	--header	set header"
			echo 	"	--guard		sets guard (default is '#rm ')"
			return
			;;
		--header)  # Takes an option argument, ensuring it has been specified.
			header=$2
			: ${header:=''}
			header="\"$header\""
			shift
			;;
		--guard)      # Takes an option argument, ensuring it has been specified.
			guard=$2
			shift
			;;
		-?*)
			printf 'find_dups: Error: Unknown option: %s\n' "$1" >&2
			return ;
			;;
		*)               # Default case: If no more options then break out of the loop.
			break
	esac

	shift
done

find $1 -type f -printf "%p\t%s\n" | \
perl -ne 'm/^(.+)\t([0-9+]+)$/ ; push @{$S{$2}}, "$1\0" ; END {for(values %S) {print @$_ if @$_ > 1}}' | \
xargs -0 md5sum | \
perl -ne "m/^([0-9a-f]{32})  (.+)\$/ ; push @{\$M{\$1}}, \$2 ; END { $fmt ; @f = values %M ; $sorting ; for(@f) { do { print $header ; print q{$guard'}, join(qq{'\n$guard'}, sort @\$_), qq{'\n} } if @\$_ > 1}}"

}

key()
{
while read -srn 1 key ; do
	case "$key" in
		# Backspace.
		$'\b'|$'\177') printf '%s\n' "key: \$'\\b' or \$'\\177'" ;;

		# Escape Sequences.
		$'\e') read -rsn 2 ; printf '%s %q\n' "key:" "${key}${REPLY}" ;;

		# Return / Enter.
		"") printf '%s\n' "key: \" \"" ;;

		# Everything else.
		*) printf '%s %q\n' "key:" "$key" ;;
	esac
done
}

