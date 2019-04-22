#!/bin/bash

################################################################
#
# Gustavo Arnosti Neves
# https://github.com/tavinus
#
# Description: Disables F1 (Help) and F11 (Fullscreen) on
#              XFCE4 terminal emulator, so those keys can 
#              be passed to the programs running in the
#              terminal.
#
# Usage ./xfceterm-disable-accels.sh
#       ./xfceterm-disable-accels.sh --help
#
# Download
#   wget '' && chmod +x xfceterm-disable-accels.sh
#   curl -O -J -L '' && chmod +x xfceterm-disable-accels.sh
#
################################################################


TRUE=0
FALSE=1

TIMESTAMP="$(date '+%Y%m%d-%H%M%S' 2>/dev/null)"

# config location: ~/.config/xfce4/terminal/accels.scm
ACCELS_SCM="$HOME/.config/xfce4/terminal/accels.scm"

SCM_TXT=""
SCM_FULLSCREEN='(gtk_accel_path "<Actions>/terminal-window/fullscreen" "")'
SCM_CONTENTS='(gtk_accel_path "<Actions>/terminal-window/contents" "")'

FLAG_FULLSCREEN=$TRUE
FLAG_CONTENTS=$TRUE


### This scripts name
XTDA_NAME="$(basename $0)"
XTDA_LOCATION="$(readlink -f $0)"

XTDAVERSION="0.0.1"
BANNERSTRING="XFCE Terminal Disable Accels v$XTDAVERSION"



# Returns $TRUE if $1 is a directory, $FALSE otherwise
isDir() {
        [[ -d "$1" ]] && return $TRUE
        return $FALSE;
}

# Returns $FALSE if $1 is a directory, $TRUE otherwise
isNotDir() {
        isDir "$1" && return $FALSE
        return $TRUE;
}

# Returns $TRUE if $1 is a file, false otherwsie
isFile() {
        [[ -f "$1" ]] && return $TRUE
        return $FALSE
}

# Returns $TRUE if $1 is NOT a file, false otherwsie
isNotFile() {
        [[ -f "$1" ]] && return $FALSE
        return $TRUE
}

# Returns $TRUE if we should disable F11 / Fulscreen
shouldFullscreen() {
	return $FLAG_FULLSCREEN
}

# Returns $TRUE if we should disable F1 / Help / Contents
shouldContents() {
	return $FLAG_CONTENTS
}

# Return $TRUE if $1 is empty, $FALSE otherwise
isEmpty() {
        [[ -z "$1" ]] && return $TRUE
        return $FALSE
}

# Return $TRUE if $1 is NOT empty, $FALSE otherwise
isNotEmpty() {
        [[ -z "$1" ]] && return $FALSE
        return $TRUE
}

rtError() {
	isNotEmpty "$1" && echo "$1" >&2
	local exitStatus=1
	isNotEmpty "$2" && exitStatus=$2
	exit $exitStatus;
}



##################### Handlers

initialChecks() {
	if isNotDir "$HOME/.config/xfce4/terminal"; then
		printBanner 'error'
		rtError "Could not find XFCE terminal config folder!"$'\n'"Seems like you don't have it installed on this system!"$'\n\n'" > $HOME/.config/xfce4/terminal"
	fi
	if isFile "$ACCELS_SCM"; then
		local backupFile="$HOME/.config/xfce4/terminal/accels-scm-backup-$TIMESTAMP"
		printError "The file accels.scm already exists, moving as a backup to"
		printError "> $backupFile"
		mv "$ACCELS_SCM" "$backupFile" || rtError "Could not create backup..."
	fi
}


prepareScm() {
	if shouldContents && shouldFullscreen; then
		SCM_TXT="$SCM_FULLSCREEN"$'\n'"$SCM_CONTENTS"$'\n'
	elif shouldContents; then
		SCM_TXT="$SCM_CONTENTS"$'\n'
	elif shouldFullscreen; then
		SCM_TXT="$SCM_FULLSCREEN"$'\n'
	fi
}



##################### Execution


# prints message to stderr
printError() {
    echo "$@" >&2
}

# prints program name and version
printBanner() {
    [[ "$1" = 'error' ]] && { printError $'\n'"$BANNERSTRING"$'\n' ; return $TRUE ; }
    local str=""
    if [[ "$1" = 'nopadding' ]]; then
        str="$BANNERSTRING"
    else
        str=$'\n'"$BANNERSTRING"$'\n'
    fi
    echo "$str"
}

# prints help to screen and exits
printHelp() {
    printBanner
    echo "Usage: $XTDA_NAME [options]
Options:
  -V, --version         Show program name and version and exits
  -h, --help            Show this help screen and exits
  -c, --no-contents     Do NOT disable F1 / Help / Contents
  -f, --no-fullscreen   Do NOT disable F11 / Fullscreen

Notes:
  - Short options should not be grouped. You must pass each parameter on its own.
  - By default, both F1 and F11 will be disabled (use flags to disble only one).

Examples:
  $XTDA_NAME              # disable F1 and F11
  $XTDA_NAME -c           # disable ONLY F11 / Fullscreen
  $XTDA_NAME -f           # disable ONLY F1 / Contents / Help
"
}



### Parse CLI options
get_options() {
    while :; do
        case "$1" in
            -V|--version|--Version)
                printBanner 'nopadding' ; exit 0 ;;
            -h|--help|--Help)
                printHelp ; exit 0 ;;
            -c|--no-contents|--nocontents|--noContents)
                FLAG_CONTENTS=$FALSE ; shift ;;
            -f|--no-fullscreen|--nofullscreen|--noFullscreen)
                FLAG_FULLSCREEN=$FALSE ; shift ;;
            *)
                checkInvalidOpts "$1" ; break ;;
        esac
    done
}

# In this script's case, just check we have and emty string and we should be fine
checkInvalidOpts() {
    if isNotEmpty "$1"; then
        printBanner
        echo "Invalid Option: $1"$'\n'
	echo "For help, try: $XTDA_NAME --help"
        exit 2
    fi
    return 0
}

main() {
	initialChecks     # may exit here (on RT error)
	prepareScm        # create config contents
	printf "%s" "$SCM_TXT" > "$ACCELS_SCM"
	if [[ $? -eq 0 ]]; then
		echo $'\nAll Done!\nPlease close and reopen your XFCE terminals to test changes!'
	else
		rtError "Error detected when creating the config file! Permissions?"
	fi
	exit 0	
}

get_options "$@"
main

