##  Bash cmpletion file for aptsources
sources () 
{
    sources=$( ls -o -g /etc/apt/sources.list.d/| grep '.list$' | awk '{print $7}' | sed 's/.list/\ /g' )

    for file in $sources ; do
        grep '^ *deb' /etc/apt/sources.list.d/"$file".list >> /dev/null

        if [ $? == 0 ] ; then
            sources_enabled="$sources_enabled $file";    # holds files with uncommented 
                                                         # lines
        else
            sources_disabled="$sources_disabled $file";  # the opposite
        fi
    done
}

_aptsources ()
{
    local command opts
    COMPREPLY=()

    command="${COMP_WORDS[COMP_CWORD]}" # User input
    
    # Options to show
    opts=" --enable --disable --src --show-source --add --remove --add-launchpad --help --list "
    
    ## If the introduced command is one of the following, keep on completing
    ## sources
    case "${COMP_WORDS[1]}" in
	--enable)
            COMPREPLY=( $(compgen -W "${sources_disabled}" -- ${command}))
            return 0;;
	--disable)
	    COMPREPLY=( $(compgen -W "${sources_enabled}" -- ${command}))
            return 0;;
	--src|--show-source|--remove)
	    COMPREPLY=( $(compgen -W "${sources}" -- ${command}))
            return 0;;
        --help|--list|--add|--add-launchpad)
            return 0;;
    esac

    # If no option is specified show all options
    if [[ ${command} = -* ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${command}) )
        return 0
    fi
}

sources
complete -F _aptsources aptsources
