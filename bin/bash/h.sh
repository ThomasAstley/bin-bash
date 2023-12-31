#!/bin/bash

# DESCRIPTION:
#   * h highlights with color specified keywords when you invoke it via pipe
#   * h is just a tiny wrapper around the powerful 'ack' (or 'ack-grep'). you need 'ack' installed to use h. ack website: http://beyondgrep.com/
# INSTALL:
#   * put something like this in your .bashrc:
#     . /path/to/h.sh
#   * or just copy and paste the function in your .bashrc
# TEST ME:
#   * try to invoke:
#     echo "abcdefghijklmnopqrstuvxywz" | h   a b c d e f g h i j k l
# CONFIGURATION:
#   * you can alter the color and style of the highlighted tokens setting values to these 2 environment values following "Perl's Term::ANSIColor" supported syntax
#   * ex.
#     export H_COLORS_FG="bold black on_rgb520","bold red on_rgb025"
#     export H_COLORS_BG="underline bold rgb520","underline bold rgb025"
#     echo abcdefghi | h   a b c d
# GITHUB
#   * https://github.com/paoloantinori/hhighlighter

h() {
    _usage() {
        echo "usage: YOUR_COMMAND | h [-idn] args...
    -i : ignore case
    -d : disable regexp
    -n : invert colors"
    }

    local _OPTS

    # detect pipe or tty
    if test -t 0; then
        _usage
        return
    fi

    OPTIND=1

    # manage flags
    while getopts ":idnQ" opt; do
        case $opt in
            i) _OPTS+=" -i " ;;
            d)  _OPTS+=" -Q " ;;
            n) n_flag=true ;;
            Q)  _OPTS+=" -Q " ;;
                # let's keep hidden compatibility with -Q for original ack users
            \?) _usage
                return ;;
        esac
    done

    shift $(($OPTIND - 1))

    # set zsh compatibility
    [[ -n $ZSH_VERSION ]] && setopt localoptions && setopt ksharrays && setopt ignorebraces

    local _i=0

    if [[ -n $H_COLORS_FG ]]; then
        local _CSV="$H_COLORS_FG"
        local OLD_IFS="$IFS"
        IFS=','
        local _COLORS_FG=()
        for entry in $_CSV; do
          _COLORS_FG=("${_COLORS_FG[@]}" "$entry")
        done
        IFS="$OLD_IFS"
    else
        _COLORS_FG=( 
                "bold yellow" \
                "bold green" \
                "bold red" \
                "bold blue" \
                "bold magenta" \
                "bold cyan"
                )
    fi

    if [[ -n $H_COLORS_BG ]]; then
        local _CSV="$H_COLORS_BG"
        local OLD_IFS="$IFS"
        IFS=','
        local _COLORS_BG=()
        for entry in $_CSV; do
          _COLORS_BG=("${_COLORS_BG[@]}" "$entry")
        done
        IFS="$OLD_IFS"
    else
        _COLORS_BG=(            
                "black on_yellow" \
                "black on_green" \
                "bold white on_red" \
                "bold white on_blue" \
                "bold white on_magenta" \
                "white on_cyan" \
                "black on_white"
                )
    fi

    if [ -z $n_flag ]; then
        #inverted-colors-last scheme
        _COLORS=("${_COLORS_FG[@]}" "${_COLORS_BG[@]}")
    else
        #inverted-colors-first scheme
        _COLORS=("${_COLORS_BG[@]}" "${_COLORS_FG[@]}")
    fi

    if [ "$#" -gt ${#_COLORS[@]} ]; then
        echo "You have passed to hhighlighter more keyords to search than the number of configured colors.
Check the content of your H_COLORS_FG and H_COLORS_BG environment variables or unset them to use default 12 defined colors."
        return -1
    fi


    local ACK=ack
    if ! which $ACK >/dev/null 2>&1; then
        ACK=ack-grep
        if ! which $ACK >/dev/null 2>&1; then
            echo "Could not find ack or ack-grep"
            return -1
        fi
    fi

    # build the filtering command
    for keyword in "$@"
    do
        local _COMMAND=$_COMMAND"$ACK $_OPTS --noenv --flush --passthru --color --color-match=\"${_COLORS[$_i]}\" '$keyword' |"
        _i=$_i+1
    done
    #trim ending pipe
    _COMMAND=${_COMMAND%?}
    # echo "$_COMMAND"
    cat - | eval $_COMMAND
}

# export -f h

[[ $0 != "$BASH_SOURCE" ]] || h "$@"

