#!/bin/bash

# http://www.faqs.org/faqs/unix-faq/programmer/faq/ describes what is necessary to be a daemon.
# Set DEBUG to true to see pretty output (but it also exits immediately rather than looping endlessly):
# Mike S @ https://stackoverflow.com/questions/3430330/best-way-to-make-a-shell-script-daemon/29107686#29107686

DEBUG=false

# This part is for fun, if you consider shell scripts fun- and I do.
trap process_USR1 SIGUSR1

process_USR1() {
    echo 'Got signal USR1'
    echo 'Did you notice that the signal was acted upon only after the sleep was done'
    echo 'in the while loop? Interesting, yes? Yes.'
    exit 0
}
# End of fun. Now on to the business end of things.

print_debug() {
    whatiam="$1"; tty="$2"
    [[ "$tty" != "not a tty" ]] && {
        echo "" >$tty
        echo "$whatiam, PID $$" >$tty
        ps -o pid,sess,pgid -p $$ >$tty
        tty >$tty
    }
}

me_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
me_FILE=$(basename $0)
cd /

#### CHILD HERE --------------------------------------------------------------------->
if [ "$1" = "child" ] ; then   # 2. We are the child. We need to fork again.
    shift; tty="$1"; shift
    $DEBUG && print_debug "*** CHILD, NEW SESSION, NEW PGID" "$tty"
    umask 0
    $me_DIR/$me_FILE XXrefork_daemonXX "$tty" "$@" </dev/null >/dev/null 2>/dev/null &
    $DEBUG && [[ "$tty" != "not a tty" ]] && echo "CHILD OUT" >$tty
    exit 0
fi

##### ENTRY POINT HERE -------------------------------------------------------------->
if [ "$1" != "XXrefork_daemonXX" ] ; then # 1. This is where the original call starts.
    tty=$(tty)
    $DEBUG && print_debug "*** PARENT" "$tty"
    setsid $me_DIR/$me_FILE child "$tty" "$@" &
    $DEBUG && [[ "$tty" != "not a tty" ]] && echo "PARENT OUT" >$tty
    exit 0
fi

##### RUNS AFTER CHILD FORKS (actually, on Linux, clone()s. See strace -------------->
                               # 3. We have been reforked. Go to work.
exec >/tmp/outfile
exec 2>/tmp/errfile
exec 0</dev/null

shift; tty="$1"; shift

$DEBUG && print_debug "*** DAEMON" "$tty"
                               # The real stuff goes here. To exit, see fun (above)
$DEBUG && [[ "$tty" != "not a tty" ]]  && echo NOT A REAL DAEMON. NOT RUNNING WHILE LOOP. >$tty

$DEBUG || {
while true; do
    echo "Change this loop, so this silly no-op goes away." >/dev/null
    echo "Do something useful with your life, young padawan." >/dev/null
    sleep 10
done
}

$DEBUG && [[ "$tty" != "not a tty" ]] && sleep 3 && echo "DAEMON OUT" >$tty

exit # This may never run. Why is it here then? It's pretty.
     # Kind of like, "The End" at the end of a movie that you
     # already know is over. It's always nice.

