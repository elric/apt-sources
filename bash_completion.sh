## Completion file for aptsources
_aptsources () 
{
    local command previous_command opts
    COMPREPLY=()

    # List sources files
    sources=$( ls -o -g /etc/apt/sources.list.d/| grep '.list$' | awk '{print $7}' | sed 's/.list/\ /g' )
    
    command="${COMP_WORDS[COMP_CWORD]}" # User input
    previous_command="${COMP_WORDS[COMP_CWORD-1]}" # shift arguments and get value
    
    # Options to show
    opts=" --enable --disable --src --list --add --remove --add-launchpad --help --list "
    
    ## If the introduced command is one of the following, keep on completing
    ## sources
    case "${COMP_WORDS[1]}" in
	--enable|--disable|--src|--remove)
	COMPREPLY=( $(compgen -W "${sources}" -- ${command}))
    esac

    ## Don't complete these options
    case "${previous_command}" in
        --help|--list|--add|--add-launchpad)
        return 0
    esac

    # If no option is specified show all options
    if [[ ${command} = -* ]]; then
    COMPREPLY=( $(compgen -W "${opts}" -- ${command}) )
    return 0
    fi
}

complete -F _aptsources aptsources
