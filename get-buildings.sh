#!/bin/bash
# 
# get buildings info in game http://www.my-industry.net
 
# Patrick CAO HUU THIEN <patrick.cao_huu_thien@upmc.fr>
# 
readonly VERSION=1
# History
# * 31 oct. 2017 - 1
# - initial version
 
function usage() {
cat <<EOT
Usage: $(basename $0) [-hnvVdn] [-p <prout> ] <x> <y>

Make a action <x> with <y>. 

Options:
    -p : do a prout :)

    -h : print this page
    -V : print version
    -v : verbose -- conflict with -q
    -q : quiet -- conflict with -v
    -n : test mode ; do not write on disk

EOT
}

## Functions ##############################################

BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
NOCOLOR="\033[0m"

function do_debug () { [ $DEBUG ] && echo -e "${BLUE}[debug]${CYAN} $@${NOCOLOR}" >&2 || false; }
#do_debug bla bla in debug
#do_debug mode debug || echo mode not debug
 
function do_crit () { cal=`caller 0`;echo "E: (line: $cal) $@" >&2; exit 1;  }
#do_crit This is an critical error
 
function do_err () { echo "E: $@" >&2; exit 1;  }
#do_err This is an error test
 
function do_err_usage () { echo "E: $@" >&2; usage; exit 1;  }
#do_err_usage This is an error with usage
 
function do_warn () { echo "W: $@";  }
#do_warn This is an error test
 
function do_print () { [ -z $QUIET ] && echo "$@"; }
#do_print this is a test
 
function do_printf () { [ -z $QUIET ] && printf "$@"; }
#do_printf "%10s_%20s_%-10s_%s\n" this is a test


function do_verbose () { [ -n "$VERBOSE" ] && echo "$@"; }

function do_test () { [ -n "$TEST" ] && { [ -n "$*" ] && echo "[test] $@" || true; }  || false; }
#do_test echo test || echo mode production
#do_test || echo mode production2

function do_trap_user() { echo "Interuption by user"; }
function do_trap_exit() { true; }

## Arguments ##############################################

OPTIND=1
while getopts hnvVdq opt ; do
   case "$opt" in
        p) PROUT="$OPTARG";;

        h) usage; exit;;
        v) VERBOSE=1;;
        d) DEBUG=1;;
        q) QUIET=1;;
        n) TEST=1;;
        V) echo "$(basename $0) - $VERSION"; exit;;
   esac
done
shift $(($OPTIND - 1))
 
# test $# == 3 || do_err_usage Missing argument

# Main ####################################################
readonly URL_BASE="http://www.my-industry.net/immobilier.php?c="
URLS="1 2 3 4 5 6 7"
test -n "$DEBUG" && URLS="1"

trap do_trap_user TERM INT
trap do_trap_exit EXIT

readonly CACHEFILE=.$(basename $0)-cache
readonly UPDATETIME=800000 #format HHMMSS

# get current update of l'Arbitre
# CURRENTUPDATE format YYMMSSHHMMSS
test "$(date +%H%M%S)" -le "$UPDATETIME" && {
	CURRENTUPDATE="$(date +%Y%m%d -d yesterday)${UPDATETIME}"
} || {
	CURRENTUPDATE="$(date +%Y%m%d)${UPDATETIME}"
}

# get date of file + 1 day
# FILEUPDATE format YYMMSSHHMMSS
test -f ${CACHEFILE} && {
	FILEDATE=$(date +%Y%m%d -r ${CACHEFILE})
	FILETIME=$(date +%H:%M:%S -r ${CACHEFILE})
} || {
	FILEDATE=19700101
	FILETIME=00:00:00
}
FILEUPDATE=$(date +%Y%m%d%H%M%S -d "${FILEDATE} ${FILETIME}+1day")

# do_debug "DATE:     $(date +%Y%m%d%H%M%S)"
# do_debug "FILE:     ${FILEDATE}"
do_debug "FILE UDP: ${FILEUPDATE}"
do_debug "UPDATE:   ${CURRENTUPDATE}"

test ${FILEUPDATE} -le ${CURRENTUPDATE} && {
	do_debug "Do an update"
	DO_UPDATE=1
} || {
	do_debug "No update needed"
}

test -z "${DO_UPDATE}" && {
	cat ${CACHEFILE}
} || {

	oIFS="$IFS"
	for u in $URLS
	do
		do_verbose "========================================================================"
		do_verbose "* URL ${URL_BASE}${u}"
		do_verbose "========================================================================"
		do_verbose "ville|loyer|surface|societe"
		table=$(wget -q -O - ${URL_BASE}${u} | xmllint --html --format --xpath '//table[3]' - 2>/dev/null)
		IFS=$'\n' ## split line with only \n
		for line in $table
		do
			# do_debug line "[[$line]]"
			test -n "$line" || continue
			ville=$(echo "$line" | xmllint --html --xpath 'string(//td[2]/a/text())' - 2>/dev/null)
			ville2=$(echo "$line" | xmllint --html --xpath 'string(//td[2]/text())' - 2>/dev/null)
			pays=$(echo $ville2|sed -n 's/^.*(\(.*\) -.*)$/\1/p')
			continent=$(echo $ville2|sed -n 's/^.*(.*- \(.*\))$/\1/p')
			# remove space in numbers
			loyer=$(echo "$line" | xmllint --html --xpath 'string(//td[3]/text())' - 2>/dev/null | sed 's@\([0-9]*\) *\([0-9]*\)@\1\2@g')
			surface=$(echo "$line" | xmllint --html --xpath 'string(//td[4]/text())' - 2>/dev/null | sed 's@\([0-9]*\) *\([0-9]*\)@\1\2@g')
			societe=$(echo "$line" | xmllint --html --xpath 'string(//td[5]/text())' - 2>/dev/null)

			test -n "$ville" -a -n "$ville2" -a -n "$loyer" -a -n "$surface" -a -n "$societe" || continue
			echo "$ville|$pays|$continent|$loyer|$surface|$societe" | tee -a ${CACHEFILE}
		done
		IFS=$oIFS
	done

}

# vim:set ts=4 sw=4 sta ai spelllang=en:

