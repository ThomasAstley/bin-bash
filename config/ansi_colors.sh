export BOLD=$'\e[01m'
export BOLD=$'\e[01m'
export UNDERLINED=$'\e[04m'
export FLASHING=$'\e[05m'

export DIM_BLACK=$'\e[2;30m'
export DIM_RED=$'\e[2;31m'
export DIM_GREEN=$'\e[2;32m'
export DIM_YELLOW=$'\e[2;33m'
export DIM_BLUE=$'\e[2;34m'
export DIM_MAGENTA=$'\e[2;35m'
export DIM_CYAN=$'\e[2;36m'
export DIM_LIGHT_GREY=$'\e[2;37m'

export BLACK=$'\e[30m'
export RED=$'\e[31m'
export GREEN=$'\e[32m'
export YELLOW=$'\e[33m'
export BLUE=$'\e[34m'
export MAGENTA=$'\e[35m'
export CYAN=$'\e[36m'
export LIGHT_GREY=$'\e[37m'

export DARK_GREY=$'\e[90m'
export LIGHT_RED=$'\e[91m'
export LIGHT_GREEN=$'\e[92m'
export LIGHT_YELLOW=$'\e[93m'
export LIGHT_BLUE=$'\e[94m'
export LIGHT_MAGENTA=$'\e[35m'
export LIHT_CYAN=$'\e[96m'
export WHITE=$'\e[97m'

export RESET=$'\e[00m'

export ON_BLACK=$'\e[40m'
export ON_RED=$'\e[41m'
export ON_GREEN=$'\e[42m'
export ON_YELLOW=$'\e[43m'
export ON_BLUE=$'\e[44m'
export ON_MAGENTA=$'\e[45m'
export ON_CYAN=$'\e[46m'
export ON_LIGHT_GREY=$'\e[47m'

export ON_DARK_GREY=$'\e[100m'
export ON_LIGHT_RED=$'\e[101m'
export ON_LIGHT_GREEN=$'\e[102m'
export ON_LIGHT_YELLOW=$'\e[103m'
export ON_LIGHT_BLUE=$'\e[104m'
export ON_LIGHT_MAGENTA=$'\e[105m'
export ON_LIGHT_CYAN=$'\e[106m'
export ON_WHITE=$'\e[107m'

ansi_colors()
{
for clbg in 040 100 ; do
	#Foreground
	for clfg in {30..37} {90..97} 39 ; do
		#Formatting
		for attr in 0 1 2 4 5 7 ; do
			#Print the result
			echo -en "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
		done
		echo #Newline
	done
done
}

ansi_colors_all()
{
for clbg in {40..47} {100..107} 49 ; do
	#Foreground
	for clfg in {30..37} {90..97} 39 ; do
		#Formatting
		for attr in 0 1 2 4 5 7 ; do
			#Print the result
			echo -en "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
		done
		echo #Newline
	done
done
}


