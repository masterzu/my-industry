#!/bin/bash
# 
# get distances info in game http://www.my-industry.net
 
# Patrick CAO HUU THIEN <patrick.cao_huu_thien@upmc.fr>
# 
readonly VERSION=1
# History
# * 17 nov 17 - 1
# - initial version
 
function usage() {
cat <<EOT
Usage: $(basename $0) [-hnvVdn] [-r] <city1> <city2> 

Print all cites with format : <id>|<city>

Options:
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
while getopts hnvVdqr opt ; do
   case "$opt" in
        h) usage; exit;;
        v) VERBOSE=1;;
        d) DEBUG=1; VERBOSE=1;;
        q) QUIET=1;;
        n) TEST=1;;
        r) RELOAD=1;;
        V) echo "$(basename $0) - $VERSION"; exit;;
   esac
done
shift $(($OPTIND - 1))
 
# test $# == 3 || do_err_usage Missing argument

# Main ####################################################
readonly URL_BASE="http://www.my-industry.net/distances.php?"
readonly CACHECITIES=.cities-cache

trap do_trap_user TERM INT
trap do_trap_exit EXIT

test -f $CACHECITIES -a -z "$RELOAD" && {
	cat "$CACHECITIES"
} || {
	rm -f "${CACHECITIES}"

	oIFS="$IFS"
	do_verbose "========================================================================"
	do_verbose "* URL ${URL_BASE}"
	do_verbose "========================================================================"
	table=$(wget -q -O - ${URL_BASE} | xmllint --html --format --xpath '//form//select[@name="d1"]' - 2>/dev/null)
	IFS=$'\n' ## split line with only \n
	for line in $table
	do
		do_debug line "[[$line]]"
		objet=$(echo "$line" | xmllint --html --xpath 'string(//option/text())' - 2>/dev/null)
		test -n "$objet" || continue
		do_debug "objet: $objet;"
		id=$(echo "$line" | xmllint --html --xpath 'string(//option/@value)' - 2>/dev/null)
		do_debug "id: $id"

		test -n "$objet" -a -n "$id" || continue
		echo "$id|$objet" |tee -a "$CACHECITIES"
	done
	IFS="$oIFS"
}




# vim:set ts=4 sw=4 sta ai spelllang=en:

