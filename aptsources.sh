#!/bin/bash  
#===============================================================================
#
#          FILE:  aptsources.sh
# 
#         USAGE: ./aptsources.sh -h
# 
#   DESCRIPTION: A script to administrate repositories configured
#                under /etc/apt/sources.list.d
#
#        AUTHOR: Omar Campagne
#       CREATED: 07/01/11 17:16:35 CET
#       VERSION: 0.3
#
#       Credits to Anant Shirvastava [1], add_lp_repo() is his.
#       [1] http://blog.anantshri.info/howto-add-ppa-in-debian/    
#===============================================================================

# TODO: Only one argument a time is allowed, update_pacakges () would benefit
# check if already enabled or disabled
# autoinstall's sed can be nicer

# check_lines doesn't work with -d because grep doesn't tell if one
# or both lines are commented. Therefore, -d fails because a repo
# counts as $sources_enabled when only the deb line is uncommented.
# I need 3 states, enabledbin, enabledsrc and disabled, or sthg like that.

help_message () { 
echo 'aptsources is a script to enable, disable and add external repositories';
echo 'under `/etc/apt/sources.list.d/`';
echo '';
echo 'Usage: ./aptsources.sh [-e -s -d -a -r] [repository filename]';
echo '       -lp [ppa:user/ppa-name  ubuntu-codename] -l -h;'
echo '';
echo 'Only one option can be specified at a time.';
echo 'Omit '.list' extension in filename/repository name.';
echo '';
echo '-e,  --enable      enable repository, only 'deb' line';
echo '-s,  --src         enable repository, 'deb-src' and 'deb' lines';
echo '-d,  --disable     disable repository';
echo '-a,  --add         add repository';
echo '-r,  --remove      remove repository';
echo '-lp, --add-lp      add launchpad repository and fetch key';
echo '-l,  --list        list repositories and status';
echo '-i,  --autoinstall install script system-wide to /usr/local/bin/';
echo '-h,  --help        this message';
exit 1
}

# Check that the user runs as root
check_root () {
    if [[ $EUID -ne 0 ]]; then
        echo "You need administrative privileges" 2>&1
        exit 1
    fi
}


### Creates $repos for --enable --src n --disable, infering which
# files don't exist

check_repos () {
    shift # move $@ to the left
    if [ ! -n "$1"  ] ; then # check args are given
        echo "No repositories have been specified"
        exit 1
    fi

    local temp_repos="$@" # get the remnants
    local repo
    local failed

    # Check existence of repos/files, and load in vars
    for repo in $temp_repos; do
        if [ ! -e /etc/apt/sources.list.d/$repo.list ] ; then
            failed="$failed $repo"
        else
            repos="$repos $repo"            
        fi
    done
    
    # Show failures only if no correct filename was introduced
    if [ "$failed" != "" ] && [ "$repos" = "" ] ; then
        echo -e "\033[1mFailed:\033[0m$failed"
        exit 1
    fi
}


#### Enable repositories

## Only binary
enable_bin_repo () {
    local repo
    for repo in $repos
	do
	sed -i -e 's/#* *deb \|#deb /deb /g' /etc/apt/sources.list.d/"$repo".list;
    done
    echo -e "\033[1mEnabled\033[0m:$repos"
}

## deb-src too
enable_binsrc_repo () {
    local repo
    for repo in $repos
	do
	sed -i -e 's/#* *deb\|#deb/deb/g' /etc/apt/sources.list.d/"$repo".list;
    done
    echo -e "\033[1mEnabled\033[0m:$repos"
}


### Disable repositories

disable_repo () {
    local repo
    for repo in $repos
        do
        sed -i -e 's/^deb\|^ *deb/# deb/g' /etc/apt/sources.list.d/"$repo".list;
    done
    echo -e "\033[1mDisabled\033[0m:$repos"
}


### Add repo

# just spawns an editor...
add_repo () {
    shift ##  we take $@ and shift it to get the reponame (the arg)
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

    local ppa_name # 1st argument
    local repo_filename # stripped from 1st arg
    local ubuntu_distribution # 2nd argument

    ppa_name=$(echo "$1" | cut -d":" -f2 -s) 
    repo_filename=$(echo $ppa_name | sed 's/\// /' | awk '{print $1}')
    ubuntu_distribution="$2"

    if [ -z "$ppa_name" ] ; then  # Check correctness of $1
        echo "PPA name not found or incorrect"
    else
    echo -e "Adding $ppa_name and updating Packages lists, this will take some time..." 
    echo "deb http://ppa.launchpad.net/$ppa_name/ubuntu $ubuntu_distribution main" >> \
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
        rm -i /etc/apt/sources.list.d/"$repo".list;
    done

    echo -e "\033[1mDeleted\033[0m:$repos"
}


## Shows sources.list.d/* and status (commented or uncommented deb lines)

list_sources () {
    local sources
    local file
    local sources_enabled
    local sources_disabled

    sources=$(ls -o -g /etc/apt/sources.list.d/| grep '.list$' | awk '{print $7}' | sed 's/.list/\ /g')

    for file in $sources ; do
        grep '^ *deb' /etc/apt/sources.list.d/"$file".list >> /dev/null

        if [ $? == 0 ] ; then
            sources_enabled="$sources_enabled $file"; # holds files with uncommented lines
        else
            sources_disabled="$sources_disabled $file"; # the opposite
        fi
    done

    echo -e "\033[1mEnabled:\033[0m$sources_enabled\n\033[1mDisabled:\033[0m$sources_disabled"
}

## Update packages at user request.

update_packages_list () {
    echo "Would you like to update the list of packages? [y/n]"
    read ans

    if [ $ans = y -o $ans = Y -o $ans = yes -o $ans = Yes -o $ans = YES ] ; then
    which aptitude  &>/dev/null 
        # Checks aptitude is installed (Ubuntu will stop doing it...)
        if [ $? == 0 ] ; then 
            aptitude update
        else
            apt-get update
        fi
    fi

    if [ $ans = n -o $ans = N -o $ans = no -o $ans = No -o $ans = NO ] ; then
    exit 1
    fi
}

### Autoinstall, + or - copy itself to /usr/local/bin. Sed comments lines in help() and "case $1 in"
## during the process. It also comments... itself (string below)
autoinstall () {
    cat $0 | sed 's/-i|--autoinstall/#-i|--autoinstall/' | sed '/install script system/s%^%#%' > /tmp/aptsources
    install -o root -m 755 -g staff -D  /tmp/aptsources /usr/local/bin/aptsources
    rm /tmp/aptsources
    echo "Done"
}

# Parse $@ and leave the remaining args to each function,
# if required

act () {
if [ ! -n "$1" ] ; then  # Show usage if no parameter is given
    help_message
    exit 1
else
    case $1 in 
        -e|--enable)        check_root;check_repos "$@";enable_bin_repo;;
        -s|--src)           check_root;check_repos "$@";enable_binsrc_repo;;
        -d|--disable)       check_root;check_repos "$@";disable_repo;;
        -a|--add)           check_root;add_repo "$@";update_packages_list;;
        -lp|--add-lp)       check_root;add_lp_repo "$@";;
        -r|--remove)        check_root;check_repos "$@";remove_repo;;
        -l|--list)          list_sources;;
        -i|--autoinstall)   check_root;autoinstall;;
        -h|--help)          help_message;;
        -*|--*)             echo "The option '$1' doesn't exist";;
    esac
fi
}

#strings=$(echo $IN) | sed 's/-/\n/'
#
#for i in $strings ; do
#    echo $i
#done

#for i in $strings
#do
#  echo $i
#done

#IN=($@)
#IFS='-' read -ra ADDR <<< $IN
#for i in "${ADDR[@]}"; do 
#     echo -$i
#done

#declare -a IN
#
#IN=(`echo "$@" | tr '-' '\n'`)
#
#echo ${IN[@]}
#OIFS="$IFS"
#IFS='-'
#arr2=($IN)
#IFS=$OIFS
#for x in ${arr2[@]}
#do
#    echo -$x
#done

#IN="$@"
#while IN='-' read -ra ADDR; do 
#      for i in ${ADDR[@]}; do
#           echo -$i
#      done 
#done <<< $IN

#user_input="$@"
#set -- $user_input
#separator='-'
#splitted_lines=($user_input)
#for x in ${user_input[@]}
#do
#     echo "$x"
#done


IN="$@"
set -- "$IN"
IFS="-"; declare -a Array=($*)
for x in ${Array[@]} ; do
    act $x
done
