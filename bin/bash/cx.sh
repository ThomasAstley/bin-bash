
# create commands that edit files in a specific directory
# also create associated "mark" commands that link files to the edit command directory

# the edit command is prefixex with DIRX_EDIT and the mark command by DIRX_MARK
DIRX_MARK=m    # prefix for mark command 
DIRX_EDIT=''   # prefix for edit command

# declare commands and the corresponding path
declare -A cs=(\
[c]="/home/tom-kubuntu/tom/bin/cheat_sheet" \
)

for c in "${!cs[@]}" ; do
	p="$DIRX_EDIT${cs[$c]}"
	mkdir -p "$p"
 
	eval "function $DIRX_MARK$c() { m_dirx $p ; } ; export -f $DIRX_MARK$c"
	eval "function $DIRX_EDIT$c() { e_dirx $p \"\$@\" ; } ; export -f $DIRX_EDIT$c"

	eval "_bgc_e$DIRX_EDIT$c() { COMPREPLY=(\$(compgen -W '--cat --path --list \$(find \"$p\" -maxdepth 1 -type l -or -type f | perl -pe \"s[$p/][]; s[\$][ ] ; chomp\")' -- \${COMP_WORDS[COMP_CWORD]})) ; }"
	complete -F "_bgc_e$DIRX_EDIT$c" "$DIRX_EDIT$c"
done

m_dirx() { for s in ${@:2} ; do [[ -e "$s" ]] && ln -s $(pwd)/"$s" "$1"/"$s" || echo "$s doesn't exist"; done ; }
export -f m_dirx

e_dirx()
{
p="$1" ;

if [[ -z "$2" ]] ; then
	echo "$1"
else
	[[ "$2" == '--list' ]] && { find $p -type f | xargs -n1 basename ; return ; }

	cmd='vi -p'
	[[ "$2" == '--cat' ]] && { cmd='cat' ; shift ; }
	[[ "$2" == '--path' ]] && { cmd='echo' ; shift ; }
	dirx_fs=(${*:2})
	$cmd ${dirx_fs[@]/#/$p/}
fi 
}
export -f e_dirx
