#!/bin/bash  
#===============================================================================
#
#          FILE:  aptsources.sh
# 
#         USAGE: ./aptsources.sh -h
#                Check function help_message () below.
# 
#   DESCRIPTION: A script to administrate repositories configured
#                under /etc/apt/sources.list.d
#
#        AUTHOR: Omar Campagne
#       CREATED: 07/01/11 17:16:35 CET
#       VERSION: 0.5
#
#       Credits to Anant Shirvastava [1], add_lp_repo() is his.
#       [1] http://blog.anantshri.info/howto-add-ppa-in-debian/    
#===============================================================================

#-------------------------------------------------------------------------------
# Functions
#-------------------------------------------------------------------------------

help_message () { 
echo 'aptsources is a script to enable, disable and add external repositories';
echo 'under `/etc/apt/sources.list.d/`';
echo '';
echo 'Usage: ./aptsources.sh [-e -s -d -sh -a -r] [repository filename]';
echo '       -alp [ppa:user/ppa-name ubuntu-codename] -l -h;'
echo '';
echo 'Only one option can be specified at a time.';
echo 'Omit '.list' extension in filename/repository name.';
echo '';
echo '-e,  --enable      enable repository, only deb line';
echo '-s,  --src         enable repository, 'deb-src' and 'deb' lines';
echo '-d,  --disable     disable repository';
echo '-sh, --show-source show contents in source file';
echo '-a,  --add         add repository';
echo '-r,  --remove      remove repository';
echo '-l,  --list        list repositories and status';
echo -e '-i,  --autoinstall install script system-wide to /usr/local/bin/\nand bash completion file to /etc/bash_completion.d/';
echo '';
echo 'Launchpad repositories only';
echo '-alp, --add-launchpad      add launchpad repository and fetch key';
echo '';
echo '--backup           backup 'sources.list' and files under 'sources.list.d/'';
echo '--restore          restore sources files from backup file';
echo '';
echo '-h,  --help        this message';
echo '';
exit 1
}

### Creates $repos for --enable --src n --disable, infering which
# files don't exist

check_repos () {
    shift                                       # move $@ to the left
    if [ ! -n "$1"  ] ; then                    # check args are given
        echo "No repositories have been specified"
        exit 1
    fi

    local temp_repos="$@"                       # get the remnants
    local repo failed

    # Check existence of repos/files, and load in $repos if
    # affirmative
    for repo in $temp_repos; do
        if [ -e /etc/apt/sources.list.d/$repo.list ] ; then
            repos="$repos $repo"            
        else
            failed="$failed $repo"
        fi
    done
    
    # Show failures only if no correct filename was introduced
    if [ "$failed" != "" ] && [ "$repos" = "" ] ; then
        echo -e "\033[1mFailed:\033[0m$failed"
        exit 1
    fi
}


#### Enable repositories
## They just take the files in $repos, and act upon them with 'sed'

## Only binary
enable_bin_repo () {
    local repo
    for repo in $repos
	do
	command sed -i -e 's/#* *deb \|#deb /deb /g' /etc/apt/sources.list.d/"$repo".list;
    done
    echo -e "\033[1mEnabled\033[0m:$repos"
}

## deb-src too
enable_binsrc_repo () {
    local repo
    for repo in $repos
	do
	command sed -i -e 's/#* *deb\|#deb/deb/g' /etc/apt/sources.list.d/"$repo".list;
    done
    echo -e "\033[1mEnabled\033[0m:$repos"
}


### Disable repositories

disable_repo () {
    local repo
    for repo in $repos
        do
        command sed -i -e 's/^deb\|^ *deb/# deb/g' /etc/apt/sources.list.d/"$repo".list;
    done
    echo -e "\033[1mDisabled\033[0m:$repos"
}


### Add repo

# just spawns an editor...

add_repo () {
    shift                     ##  we take $@ and shift it to get the reponame (the arg)
    if [ ! -n "$1"  ] ; then
        echo "No filename or repository name specified"
        exit 1
    fi 
    touch "/tmp/$1.list"
    echo "#### $1 ####" >> /tmp/$1.list
    editor "/tmp/$1.list"
    cp /tmp/$1.list /etc/apt/sources.list.d/$1.list
    rm /tmp/$1.list 

    echo -e "\033[1mAdded\033[0m: $1"
}

### adds a launchpad ppa and fetches key

add_lp_repo () {
    shift

    # Check # of args

    if [ $# != 2 ]; then
        echo "This parameter requires two arguments: 'ppa:user/ppa-name' and 'Ubuntu codename'"
        echo "Select the one closest to your system."
    fi

    local ppa_name                              # 1st argument
    local repo_filename                         # stripped from 1st arg
    local ubuntu_distribution                   # 2nd argument

    ppa_name=$(echo "$1" | cut -d":" -f2 -s) 
    repo_filename=$(echo $ppa_name | sed 's/\// /' | awk '{print $1}')
    ubuntu_distribution="$2"

    if [ -z "$ppa_name" ] ; then                # Check correctness of ppa-name
        echo "PPA name not found or incorrect"
    else
    echo -e "Adding $ppa_name and updating Packages lists, this will take some time..." 
    echo -e "deb http://ppa.launchpad.net/$ppa_name/ubuntu $ubuntu_distribution main\ndeb-src http://ppa.launchpad.net/$ppa_name/ubuntu $ubuntu_distribution main" >> \
         /etc/apt/sources.list.d/$repo_filename.list;
         apt-get update >> /dev/null 2> /tmp/apt_add_key.txt;
         key=`cat /tmp/apt_add_key.txt | cut -d":" -f6 | cut -d" " -f3`;
         apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key
    fi
}


### Remove .list file

remove_repo () {
    local repo

    for repo in $repos
        do
        command rm -i /etc/apt/sources.list.d/"$repo".list;
    done

    echo -e "\033[1mDeleted\033[0m:$repos"
}


## Shows sources.list.d/* and status (commented or uncommented deb lines)

list_repos () {
    local repos repo repos_enabled repos_disabled

    repos=$(ls -o -g /etc/apt/sources.list.d/| command grep '.list$' | command awk '{print $7}' | command sed 's/.list/\ /g')

    for repo in $repos ; do
        command grep '^ *deb' /etc/apt/sources.list.d/"$repo".list >> /dev/null

        if [ $? == 0 ] ; then
            repos_enabled="$repos_enabled $repo";    # holds files with uncommented 
                                                         # lines
        else
            repos_disabled="$repos_disabled $repo";  # the opposite
        fi
    done

    echo -e "\033[1mEnabled:\033[0m$repos_enabled\n\033[1mDisabled:\033[0m$repos_disabled"
}

show_repos () {
    local repo
    for repo in $repos; do
        command cat /etc/apt/sources.list.d/"$repo".list
    done
}

##### Backup/Restore functions #######

backup_repos () {

    date_string=$(date +%F)

    ### Copy files and create tar.gz

    mkdir -p /tmp/.repos_backup/sources.list.d/
    command cp -r /etc/apt/sources.list.d/ /tmp/.repos_backup/
    command cp  /etc/apt/sources.list /tmp/.repos_backup

    cd /tmp/.repos_backup
    command tar czf sources.backup.$date_string.tar.gz *

    # Copy to .
    cp /tmp/.repos_backup/sources.backup.$date_string.tar.gz $OLDPWD
    cd $OLDPWD
    rm -fr /tmp/.repos_backup
    echo "Backup file created as 'sources.backup.$date_string.tar.gz'."
}

restore_repos () {
    shift

    if [ ! -n "$1"  ] ; then                    # check file is given
        echo "No file has been specified"
        exit 1
    fi

    echo -e "This action will overwrite your actual 'sources.list' and files under\n'sources.list.d/' with identical filenames to the ones contained in the backup\nfile."
    read -n1 -p "Continue? [y/n]"

    if [[ $REPLY == "y" ]] ; then
        tar zxvf $1 -C /etc/apt/                ## extract files
        echo -e "\033[1mDone\033[0m"
    else
        exit 1
    fi
}

######################################

check_root () {

    if [ ! $( id -u ) -eq 0 ]; then
       echo "Please enter root's password."
       exec su -c "${0} ${CMDLN_ARGS}"         # Call this prog as root
       exit ${?}                               # since we're 'execing' above, we wont reach
    fi                                         # this exit unless something goes wrong.
    
}                                                                     

##  Autoinstall
# Installs the script under /usr/local/bin, deleting autoinstall() and Bash
# completion section

autoinstall () {

    ## Install aptsources script
    command cat $0 | sed '/^##  Bash/,/^##  Bash/d' | sed '/^##  Autoinstall/,/^##  Autoinstall/d' | sed '/--autoinstall/d' > /tmp/aptsources
    install -o root -m 755 -g staff -D  /tmp/aptsources /usr/local/bin/aptsources
    rm /tmp/aptsources

    ## Install bash completion
    command cat $0 | sed -n '/^##  Bash/,/^##  Bash/p' | sed 's/^#//' > /tmp/aptsources_bashcompletion
    install -o root -m 644 -g root -D /tmp/aptsources_bashcompletion /etc/bash_completion.d/aptsources
    rm /tmp/aptsources_bashcompletion

    echo -e "\033[1mDone\033[0m"
}
##  Autoinstall

##  Bash completion file for aptsources
#repos () 
#{	
#    local repo
#    all_repos=$( command ls -o -g /etc/apt/sources.list.d/| grep '.list$' | awk '{print $7}' | sed 's/.list/\ /g' )
#
#    for repo in $all_repos ; do
#        command grep '^ *deb' /etc/apt/sources.list.d/"$repo".list >> /dev/null
#
#        if [ $? == 0 ] ; then
#            repos_enabled="$repos_enabled $repo";    # holds files with uncommented 
#                                                         # lines
#        else
#            repos_disabled="$repos_disabled $repo";  # the opposite
#        fi
#    done
#}
#
#_aptsources ()
#{
#    local cur opts
#    COMPREPLY=()
#
#    cur="${COMP_WORDS[COMP_CWORD]}" # User input
#    
#    # Options to show
#
#    opts="--enable --disable --src --show-source --add --remove --add-launchpad --help --list --backup --restore"
#    
#    ## If the introduced command is one of the following, keep on completing
#    ## sources
#
#    case "${COMP_WORDS[1]}" in
#	--enable|-e)
#            repos
#            COMPREPLY=( $(compgen -W "${repos_disabled}" -- "${cur}"))
#            unset repos_enabled repos_disabled
#            return 0;;
#	--disable|-d)
#            repos
#	    COMPREPLY=( $(compgen -W "${repos_enabled}" -- "${cur}"))
#            unset repos_enabled repos_disabled
#            return 0;;
#	--src|-s|--show-source|-sh|--remove|-r)
#            repos
#	    COMPREPLY=( $(compgen -W "${all_repos}" -- "${cur}"))
#            return 0;;
#        --help|-h|--list|-l|--add|-a|--add-launchpad|-alp|--backup) ## These don't return anything
#            return 0;;
#    esac
#    # If no option is specified show all options
#
#    if [[ ${command} = * ]]; then
#        COMPREPLY=( $( compgen -W "${opts}" -- "${cur}" ) )
#        return 0
#    fi
#}
#
#complete -F _aptsources aptsources
##  Bash completion file for aptsources

#-------------------------------------------------------------------------------
#  "Initialization" starts here
#-------------------------------------------------------------------------------

CMDLN_ARGS="$@"               # Command line arguments for this script, this value is
export CMDLN_ARGS             # used by check_root (). This needs to be set before the 
                              # case block so su can rerun the script with the same args

# Parse $@ and leave the remaining args to each function,
# if required

if [ ! -n "$1" ] ; then                         # Show usage if no parameter is given
    help_message
    exit 1
else
    case $1 in
        -e|--enable)        check_root;check_repos "$@";enable_bin_repo;;
        -s|--src)           check_root;check_repos "$@";enable_binsrc_repo;;
        -d|--disable)       check_root;check_repos "$@";disable_repo;;
        -a|--add)           check_root;add_repo "$@";;
        -alp|--add-launchpad)
                            check_root;add_lp_repo "$@";;
        -r|--remove)        check_root;check_repos "$@";remove_repo;;
        -sh|--show-source)  check_repos "$@";show_repos;;
        -i|--autoinstall)   check_root;autoinstall;;
        -l|--list)          list_repos;;
        --backup)           backup_repos;;
        --restore)          check_root;restore_repos "$@";;
        -h|--help)          help_message;;
        -*|--*)             echo "The option '$1' doesn't exist";;
    esac
fi
