# -*-shell-script-*-

# stray_common - utilities for managing document search index with Hyper Estraier.
#
# Copyright (C) 2016 Amit Ramon <amit.ramon@riseup.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


DEFAULT_CONF_FILES=("" "$HOME/.estwrapper.d/settings" "$HOME/.estwrapper" "/etc/estwrapper")
LOG_TAG=${0##*/}
USE_SYSLOG=false
STD_ERR=2			# file dsecriptor pointing to stderr

# These are calculated and set after loading configuration file
EST_DB=			# index database
BUILDLOG=		# index build log file
README=			# index build summary file


#---------------------------------------------------------------------------
# Test its argument for truth value.
#   A 'true' argument is one that contains 'yes', 'true' or '1',
#   in any letter case. Any other value, or unset argument, is
#   considered as false.
# Globals:
#   None
# Arguments:
#   $1 the name of the variable to test (i.e., it should be passed
#   without a $ prefix)
# Returns:
#   0 if true, 1 otherwise
#---------------------------------------------------------------------------
function is_true()
{
    local val=${!1:-}		# deref arg, test if unset
    val=${val,,}		# normalize to lowercase
    [[ $val = true || $val = yes || $val = 1 ]]
    return $?
}

#---------------------------------------------------------------------------
# Simple error handle - prints message to stderr and exit.
# 
# Parametr 1: message to print.
#---------------------------------------------------------------------------
function die()
{
    echo "$LOG_TAG: ERROR: $*" >&2
    exit 1
}

#---------------------------------------------------------------------------
# Duplicate stderr on file descriptor 3 to enable log_message to write
# to stderr even when fd 2 is redirected.
# NOTE: To be effective this function must be called before any possible
# duplication of stderr occurs.
#---------------------------------------------------------------------------
function init_log()
{
    exec 3>&2
    STD_ERR=3
}

#---------------------------------------------------------------------------
# Writes a message to the system log or to stderr, according to
# the value of USE_SYSLOG.
#
# Parametr 1: message to print.
#---------------------------------------------------------------------------
function log_msg()
{
    if $USE_SYSLOG; then
	logger -t "$LOG_TAG" "$*"
    else
        date "+%Y-%m-%d %H:%M:%S $LOG_TAG: $*" >&${STD_ERR}
    fi
}

#---------------------------------------------------------------------------
# Generate a debug message that includes function call stack informaiton.
# 
# Parametr 1: message to print.
#---------------------------------------------------------------------------
function log_debug()
{
    log_msg ">>> " ${#FUNCNAME[*]} ${FUNCNAME[1]} ${BASH_LINENO[1]} ":: $*"
    # :				# noop
}

#---------------------------------------------------------------------------
# Decode a URL-encoded string and print it to stdout.
# 
# Parametr 1: string to decode.
#---------------------------------------------------------------------------
function url_decode()
{
    printf "%b\n" "$(sed -e 's/%\([0-9A-F][0-9A-F]\)/\\\x\1/g' <<< $1)"
}

#---------------------------------------------------------------------------
# Iterator - loop over list and process each element using the
# supplied command.
#
# Parametr 1: command to call on each list's element
# Parametr 2: a name of a list of elements to process
#---------------------------------------------------------------------------
function iterate_list()
{
    local command=$1
    local -n the_list=$2	# for this pass just array name
    
    #---------------------------------------------------------------------------
    # Loop over list and process each element
    #---------------------------------------------------------------------------
    for element in "${the_list[@]}"; do
	eval "$command" "'$element'"
    done
}

#---------------------------------------------------------------------------
# Iterate through the list of directoris to index and index files under them.
#---------------------------------------------------------------------------
function build_indexes()
{
    iterate_list "process_dir _build_index" DIR_LIST
}

#---------------------------------------------------------------------------
# Iterate through the list of directoris to index and list the files
# that would be indexed.
#---------------------------------------------------------------------------
function list_files_to_index()
{
    iterate_list "process_dir _list_files" DIR_LIST
}

#---------------------------------------------------------------------------
# Generate search index keys and optimize search database.
#---------------------------------------------------------------------------
function optimize_search_db()
{
    estcmd extkeys "$EST_DB"
    sleep 1
    estcmd optimize "$EST_DB"
    estcmd purge -cl "$EST_DB"
}

#---------------------------------------------------------------------------
# Update the log file - possibly filter out unnecessary entries,
# save old log and create a new one.
#
# Parametr 1: full path of the index build log file
#---------------------------------------------------------------------------
function update_log()
{
    local buildlog=$1

    if is_true $CLEAN_LOG; then
	# Clean up and link the logfile.
	sed_cmd='
/passed .old document./d
/: passed$/d
/filling the key cache/d
/cleaning dispensable/d
'
	sed -e "$sed_cmd" $buildlog > ${buildlog}.tmp && mv ${buildlog}.tmp $buildlog
    fi

    if is_true $KEEP_LOGS; then
	log_archive=$(dirname $buildlog)/$(date "+log/%Y")
	mkdir -p $log_archive
	latest_log=$log_archive/$(date "+%m%d")
	test -f $latest_log && rm $latest_log
	ln $buildlog $latest_log || die "ln $buildlog $latest_log failed"
    fi
}

#---------------------------------------------------------------------------
# Update the README file, a brief summary of the index generation
# process.
#
# Parametr 1: full path of the build README file
# Parametr 2: full path of the index build log file
#---------------------------------------------------------------------------
function update_readme()
{
    local readme=$1
    local buildlog=$2
    cp /dev/null $readme	# empty old README

    #---------------------------------------------------------------------------
    # Count types of errors in the build log file
    #---------------------------------------------------------------------------
    local opts=$-; set +e	# don't exit if grep fails (i.e. nothing found)
    new_doc_count=$(grep -c '^estcmd: INFO:.*registered$' $buildlog)
    total_error_count=$(grep -c '^estcmd: ERROR:' $buildlog)
    size_error_count=$(grep -c '^estcmd: ERROR:.*exceeding the file size limitation$' $buildlog)
    general_error_count=$(( total_error_count - size_error_count ))
    [[ -z ${opts/*e*/} ]] && set -e

    #---------------------------------------------------------------------------
    # Add summary and error count to the readme file.
    #---------------------------------------------------------------------------
    {
	echo $(date)
	test -d "$EST_DB" && estcmd inform "$EST_DB"
	echo
	printf '%d new documents added\n' $new_doc_count
	(( size_error_count > 0 )) && \
	    printf '%d documents not processed due to lareg size (greater than %d MB)\n' \
		   $size_error_count $MAX_FILE_SIZE
	(( general_error_count > 0 )) && \
	    printf '%d errors occurred during processing\n' $general_error_count
	echo
    } > $readme

    #---------------------------------------------------------------------------
    # Send summary to the log.
    #---------------------------------------------------------------------------
    log_msg $(printf 'new docs %d, not processed due to size %d, errors %d' \
		    $new_doc_count $size_error_count $general_error_count)
}

#---------------------------------------------------------------------------
# Create rdeame file and clean log file
#
# Parametr 1: path to log file
# Parametr 2: path to readme file
#---------------------------------------------------------------------------
function update_build_info()
{
    update_readme "$2" "$1"
    update_log "$1"
}

#---------------------------------------------------------------------------
# Add a possible user configuration file to the configuration files'
# search list.
#
# Parametr 1: user configuration file
#---------------------------------------------------------------------------
function add_user_conf_file()
{
    if [[ -n $1 && -r $1 ]]; then
	DEFAULT_CONF_FILES[0]="$1"
    else
	die "Invalid or non-existing configuration file: $1"
    fi
}    

#---------------------------------------------------------------------------
# Print index database summary
#
# Parametr 1: full path to the etraier database directory
#---------------------------------------------------------------------------
function db_summary()
{
    estcmd inform "$1"
}

#---------------------------------------------------------------------------
# Print index database list of files
#
# Parametr 1: full path to the estraier database directory
#---------------------------------------------------------------------------
function db_list()
{
    #---------------------------------------------------------------------------
    # convert the URL-encoded file names to normal names and print them
    #---------------------------------------------------------------------------    
    while read line; do
	printf "%b\n" "$line"
    done < <(estcmd list "$1" | sed -e 's/%\([0-9A-F][0-9A-F]\)/\\\\\x\1/g')
}

#---------------------------------------------------------------------------
# Search the list of potential configuration files and load the
# first file found.
#---------------------------------------------------------------------------
function load_conf()
{
    local has_conf=false
    
    for conf_file in "${DEFAULT_CONF_FILES[@]}"; do
	if test -r "$conf_file"; then
	    . "$conf_file"
	    has_conf=true
	    break
	fi
    done
    
    if ! $has_conf; then
	die "Invalid or non-existing configuration file:" $conf_file
    fi
}

#---------------------------------------------------------------------------
# Search the database for the given phrase. Files found are symlinked
# in the results directory.
#---------------------------------------------------------------------------
function search_db()
{
    local opts=$-; set +f
    rm -fr "${RESULTS_DIR}"/*
    [[ -z ${opts/*f*/} ]] && set -f
    
    echo "Searching with HyperEstraier"
    echo "Search for what?"
    IFS= read -r phrase

    local count=0

    while read file; do
	ln -fs "$file" "$RESULTS_DIR"
	((count++)) || true	# don't fail because fo the non-zero value of ++
    done < <(estcmd search -max $SRCH_MAX_RESULTS -vx -sfr $EST_DB $phrase |\
                     sed -n 's#.*_lreal.*value=\"\(/.*\)\"/>$#\1#p')

    if (($count == $SRCH_MAX_RESULTS)); then
    	echo "Found $SRCH_MAX_RESULTS or more results. Showing $SRCH_MAX_RESULTS"
    else
    	echo "Found $count results"
    fi
}

#---------------------------------------------------------------------------
# Search the database for the given phrase, print results to stdout.
#---------------------------------------------------------------------------
function human_search_db()
{
    echo "Searching with HyperEstraier"
    echo "Search for what?"
    IFS= read -r phrase

    local uri_pattern="URI: file:///"
    
    while read line; do
	if [[ ${line:0:${#uri_pattern}} = $uri_pattern ]]; then
	    url_decode "$line"
	else
	    echo $line
	fi
    done < <(estcmd search -max $SRCH_MAX_RESULTS -vh -sfr $EST_DB $phrase)
}

#---------------------------------------------------------------------------
# Generate or update the search database.
#---------------------------------------------------------------------------
function update_search_db()
{
    log_msg "Starting document indexing..."
    [[ -f $BUILDLOG ]] && rm $BUILDLOG
    main_index_build >> $BUILDLOG 2>&1
    update_build_info "$BUILDLOG" "$README"
    log_msg "Finished building index"
}

#---------------------------------------------------------------------------
# Usage info 
#---------------------------------------------------------------------------
function usage()
{
    cat << EOT
Usage: ${0##*/} [OPTION]....
Build document search index database.

  -B              view the last build log
  -f <file>       specify an alternate configuration file
  -h              display this help and exit
  -H              search, print human-readable results
  -I              print brief database information
  -l              list the files that would be indexed
  -L              list database indexed files
  -s              log messages to syslog (default: stdout)
  -S              search, symlink found files in results dir
  -t <tag>        tag log messages with this tag (default: script name)

With no options other than -fst, generates or updates the search
database.

Default configuration files are seached for in this order: 
~/.estwrapper.d/settings ~/.estwrapper /etc/estwrapper
EOT
}

#---------------------------------------------------------------------------
# Main - process command line options and take necessary
# actions.
#---------------------------------------------------------------------------
function main()
{
    OPTIND=1 # Reset just to be on the safe side
    local only_list_files=false print_db_summary=false local print_db_list=false \
	  do_search=false local do_human_search=false local view_buildlog=false
    
    init_log

    while getopts "hf:lst:LISHB" opt $*; do
	case "$opt" in
            h)  usage >&2
		exit 0
		;;
            v)  verbose=$((verbose+1))
		;;
            f)  add_user_conf_file "$OPTARG"
		;;
	    t)  LOG_TAG="$OPTARG"
		;;
	    s)  USE_SYSLOG=true
		;;
	    l)  only_list_files=true
		;;
	    L)  print_db_list=true
		;;
	    I)  print_db_summary=true
		;;
	    S)  do_search=true
	        ;;
	    H)  do_human_search=true
	        ;;
	    B)  view_buildlog=true
	        ;;
            '?')
	    	usage >&2
	    	exit 1
	    	;;
	esac
    done

    shift "$((OPTIND-1))" # Shift off the options and optional --.

    #---------------------------------------------------------------------------
    # load configuration settings and set variables.
    #---------------------------------------------------------------------------
    load_conf
    EST_DB="${!DB_ROOT_DIR}/est_db"	   # index database
    BUILDLOG="${!DB_ROOT_DIR}/BUILDLOG" # index build log file
    README="${!DB_ROOT_DIR}/README"	   # index build summary file
    RESULTS_DIR="${!RESULTS_DIR}"
    DIR_LIST=( "${!DIR_LIST_NAME}" ) # indirection of array name

    if [[ -n ${FILTER_PATH:-} ]]; then
	export PATH=$FILTER_PATH:$PATH
    fi
    
    #---------------------------------------------------------------------------
    # start processing options
    #---------------------------------------------------------------------------
    
    if $view_buildlog; then
	exec less $BUILDLOG
    fi
    
    if $print_db_summary; then db_summary $EST_DB; fi
    if $print_db_list; then db_list $EST_DB; fi
    if $only_list_files; then list_files_to_index; fi
    if $do_search; then search_db; fi
    if $do_human_search; then human_search_db; fi
    
    if $print_db_summary || $print_db_list || $only_list_files ||\
	    $do_search || $do_human_search
    then
	exit
    fi

    update_search_db
}

#---------------------------------------------------------------------------
# Main entry point - select type of index to build, set appropriate
# variables accordingly, and invoke the main function.
#---------------------------------------------------------------------------
function execute_main()
{
    if [[ $1 = "mail" ]]; then
	DB_ROOT_DIR=MAIL_SEARCH_DB
	RESULTS_DIR=MAIL_RESULTS
	DIR_LIST_NAME=MAIL_DIRS[@] # set the name of the array
    elif [[ $1 = "doc" ]]; then
	DB_ROOT_DIR=DOC_SEARCH_DB
	RESULTS_DIR=DOC_RESULTS
	DIR_LIST_NAME=DOC_DIRS[@] # set the name of the array
    else
	die "Bad command: $1"
    fi

    shift
    main $*
}

