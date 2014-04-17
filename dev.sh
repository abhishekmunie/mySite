#!/usr/bin/env bash
# dev.sh <build-dir> <cache-dir>

cd "$(dirname "$0")"

CURR_DIR=`pwd`

newtab() {

    # If this function was invoked directly by a function named 'newwin', we open a new *window* instead
    # of a new tab in the existing window.
    local funcName=$FUNCNAME
    local targetType='tab'
    local targetDesc='new tab in the active Terminal window'

    # Option-parameters loop.
    inBackground=0
    while (( $# )); do
        case "$1" in
            -g)bundle
                inBackground=1
                ;;
            -G)
                inBackground=2
                ;;
            --) # Explicit end-of-options marker.
                shift   # Move to next param and proceed with data-parameter analysis below.
                break
                ;;
            -*) # An unrecognized switch.
                echo "$FUNCNAME: PARAMETER ERROR: Unrecognized option: '$1'. To force interpretation as non-option, precede with '--'. Use -h or --h for help." 1>&2 && return 2
                ;;
            *)  # 1st argument reached; proceed with argument-parameter analysis below.
                break
                ;;
        esac
        shift
    done

    # All remaining parameters, if any, make up the command to execute in the new tab/window.

    local CMD_PREFIX='tell application "Terminal" to do script'

        # Commands for opening a new tab in the current Terminal window.
        # Sadly, there is no direct way to open a new tab in an existing window, so we must activate Terminal first, then send a keyboard shortcut.
    local CMD_ACTIVATE='tell application "Terminal" to activate'
    local CMD_NEWTAB='tell application "System Events" to keystroke "t" using {command down}'
        # For use with -g: commands for saving and restoring the previous application
    local CMD_SAVE_ACTIVE_APPNAME='tell application "System Events" to set prevAppName to displayed name of first process whose frontmost is true'
    local CMD_REACTIVATE_PREV_APP='activate application prevAppName'
        # For use with -G: commands for saving and restoring the previous state within Terminal
    local CMD_SAVE_ACTIVE_WIN='tell application "Terminal" to set prevWin to front window'
    local CMD_REACTIVATE_PREV_WIN='set frontmost of prevWin to true'
    local CMD_SAVE_ACTIVE_TAB='tell application "Terminal" to set prevTab to (selected tab of front window)'
    local CMD_REACTIVATE_PREV_TAB='tell application "Terminal" to set selected of prevTab to true'

    local CMD_CLOSE_ON_EXIT=''

    if (( $# )); then # Command specified; open a new tab or window, then execute command.
            # Use the command's first token as the tab title.
        local tabTitle=$1
        case "$tabTitle" in
            exec|eval) # Use following token instead, if the 1st one is 'eval' or 'exec'.
                tabTitle=$(echo "$2" | awk '{ print $1 }')
                ;;
            cd) # Use last path component of following token instead, if the 1st one is 'cd'
                tabTitle=$(basename "$2")
                ;;
        esac
        local CMD_SETTITLE="tell application \"Terminal\" to set custom title of front window to \"$tabTitle\""
            # The tricky part is to quote the command tokens properly when passing them to AppleScript:
            # Step 1: Quote all parameters (as needed) using printf '%q' - this will perform backslash-escaping.
        local quotedArgs=$(printf '%q ' "$@")
            # Step 2: Escape all backslashes again (by doubling them), because AppleScript expects that.
#        local cmd="$CMD_PREFIX \"cd \\\"$CURR_DIR\\\"; ${quotedArgs//\\/\\\\}; osascript -e 'tell application \\\"Terminal\\\" to activate' -e 'tell application \\\"System Events\\\" to tell process \\\"Terminal\\\" to keystroke \\\"w\\\" using {command down}';\""
        local cmd="$CMD_PREFIX \"cd \\\"$CURR_DIR\\\"; ${quotedArgs//\\/\\\\} \""
            # Open new tab or window, execute command, and assign tab title.
            # '>/dev/null' suppresses AppleScript's output when it creates a new tab.

        if (( inBackground )); then
            # !! Sadly, because we must create a new tab by sending a keystroke to Terminal, we must briefly activate it, then reactivate the previously active application.
            if (( inBackground == 2 )); then # Restore the previously active tab after creating the new one.
                osascript -e "$CMD_SAVE_ACTIVE_APPNAME" -e "$CMD_SAVE_ACTIVE_TAB" -e "$CMD_ACTIVATE" -e "$CMD_NEWTAB" -e "$cmd in front window" -e "$CMD_SETTITLE" -e "$CMD_REACTIVATE_PREV_APP" -e "$CMD_REACTIVATE_PREV_TAB" >/dev/null
            else
                osascript -e "$CMD_SAVE_ACTIVE_APPNAME" -e "$CMD_ACTIVATE" -e "$CMD_NEWTAB" -e "$cmd in front window" -e "$CMD_SETTITLE" -e "$CMD_REACTIVATE_PREV_APP" >/dev/null
            fi
        else
            osascript -e "$CMD_ACTIVATE" -e "$CMD_NEWTAB" -e "$cmd in front window" -e "$CMD_SETTITLE" >/dev/null
        fi
    else
        if (( inBackground )); then
            # !! Sadly, because we must create a new tab by sending a keystroke to Terminal, we must briefly activate it, then reactivate the previously active application.
            if (( inBackground == 2 )); then # Restore the previously active tab after creating the new one.
                osascript -e "$CMD_SAVE_ACTIVE_APPNAME" -e "$CMD_SAVE_ACTIVE_TAB" -e "$CMD_ACTIVATE" -e "$CMD_NEWTAB" -e "$CMD_REACTIVATE_PREV_APP" -e "$CMD_REACTIVATE_PREV_TAB" >/dev/null
            else
                osascript -e "$CMD_SAVE_ACTIVE_APPNAME" -e "$CMD_ACTIVATE" -e "$CMD_NEWTAB" -e "$CMD_REACTIVATE_PREV_APP" >/dev/null
            fi
        else
            osascript -e "$CMD_ACTIVATE" -e "$CMD_NEWTAB" >/dev/null
        fi
    fi

}

rm -rf bin
rm -rf lib/mySite


newtab -G coffee -cbwm --output lib/mySite src/mySite

newtab -G coffee -cbw --no-header --output bin src/bin/cli.coffee

newtab -G nodemon --watch bin/cli.js --exec "mv bin/cli.js bin/mysite"

newtab -G nodemon --watch bin/mySite --exec "chmod 775 bin/mysite"

newtab -G PATH=bin:$PATH NODE_ENV='development' DEBUG='*' nodemon --watch bin/mysite --watch lib --exec "mysite --source test/site serve --livereload"

# newtab -G jekyll build --config _config.dev.yml --watch
