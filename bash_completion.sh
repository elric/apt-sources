_aptsources () 
{
    local command previous_command opts
    COMPREPLY=()

    command="${COMP_WORDS[COMP_CWORD]}" # User input
    previous_command="${COMP_WORDS[COMP_CWORD-1]}" # shift arguments and get value
    opts=" --enable --disable --src --list --add --remove --add-launchpad --help --list "

    ## First, see if an option has already been specified by user or bash_compl

    case "${previous_command}" in
        --enable|--disable|--remove)
        sources=$(ls -o -g /etc/apt/sources.list.d/| grep '.list$' | awk '{print $7}' | sed 's/.list/\ /g') 
       COMPREPLY=( $(compgen -W "${sources}" --  ${command}) ) 
        return 0
    esac
    
    ## Don't complete these options
    case "${previous_command}" in
        --help|--list|--add|--add-launchpad)
        return 0
    esac

    # If no option is specified show all options

    COMPREPLY=( $(compgen -W "${opts}" -- ${command}) )
    return 0
}

complete -F _aptsources aptsources
