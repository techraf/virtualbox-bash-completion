_vboxmanage_wait() 
{
    [ -z ${1-} ] && { echo -n " wait..."; return ;}
    
    local flag="_vboxmanage_wait_flag_${1}"
    
    [ ${!flag:-0} -ne 1 ] && {
        echo -n " wait..."
        eval ${flag}=1
    }
}

_vboxmanage_else_words()
{
    myWords=$( echo $subCommand | tr '|,[]' ' ' \
        | command grep -Po '(?<= |^)\w[\w\-]+\w(?= |$)' \
        | command sed -rn 's/ off //g;p' | command sort -u )
    COMPREPLY=($(compgen -W "${myWords}" -- ${cur}))
}

_vboxmanage_snapname()
{
    #_vboxmanage_wait
    myWords=$(eval vboxmanage snapshot "${COMP_WORDS[2]}" list --machinereadable \
        | command nl -n rz -w 2 -s ' ')
    IFS=$'\n'
    COMPREPLY=($(compgen -W "${myWords}" -- ${cur}))
}

_vboxmanage_vmname()
{
    #_vboxmanage_wait
    myWords=$(vboxmanage list vms | command nl -n rz -w 2 -s ' ' )
    IFS=$'\n'
    COMPREPLY=($(compgen -W "${myWords}" -- ${cur}))
}

_vboxmanage_double_quotes()
{
    if [[ $COMP_CWORD -eq 4 \
        && ( $prev = --snapshot || $subCommandRaw =~ "${prev} <uuid|snapname>" ) ]]
    then
        #_vboxmanage_wait snap
        myWords=$(eval vboxmanage snapshot "${COMP_WORDS[2]}" list \
            | command sed -r 's/^.*Name: //;s/ \(.+$//')
    else
        #_vboxmanage_wait vms
        myWords=$(vboxmanage list vms | command sed -r 's/ \{[^\}]+\}//g')
    fi
    IFS=$'\n'
    COMPREPLY=($(compgen -W "${myWords}" -- ${cur}))
}

_vboxmanage_ostype()
{
    myWords=$(vboxmanage list ostypes | command sed -rn '/^ID:/{s/^ID: *//;p}' | command sort -u)
    COMPREPLY=($(compgen -W "${myWords}" -- ${cur}))
}

_vboxmanage_subcommands()
{
    myWords=$(vboxmanage | command sed '1,/Commands:/d;/Introspection/,$d' \
        | command cut -d ' ' -f3 | command sort -u)
    myWords+=" extpack debugvm"
    COMPREPLY=($(compgen -W "${myWords}" -- ${cur}))
}

_vboxmanage_options() 
{
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=($(compgen -W "--version --nologo --settingspw --settingspwfile" -- ${cur}))
    else
        myWords=$( echo $subCommand | command grep -o -Ee "--[[:alnum:]-]+" | command sort -u)
        COMPREPLY=($(compgen -W "${myWords}" -- ${cur}))
    fi
}

_vboxmanage_main() 
{
    COMPREPLY=()
    local cur=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD-1]}
    local comm1=VBoxManage
    local comm2=${COMP_WORDS[1]}
    local myWords subCommandRaw subCommand
    local IFS=$' \t\n'

    if [ $COMP_CWORD -ge 2 ]; then
        if [[ $comm2 =~ ^- ]]; then
            return
        else
            if [ $comm2 = debugvm ]; then  
                subCommandRaw=$( $comm1 $comm2 | command tail -n +2 | command tr -s ' ' \
                    | command sed -rn '1p;2,${s/VBoxManage debugvm <uuid\|vmname>//;p}' )
            elif [ $comm2 = extpack ]; then
                subCommandRaw=$( $comm1 $comm2 | command tail -n +2 | command tr -s ' ' \
                    | command sed -rn '1p;2,${s/VBoxManage extpack//;p}' )
            else
                subCommandRaw=$( $comm1 $comm2 | command tail -n +3 | command tr -s ' ' \
                    | command sed -rn '1p;2,${s/'"$comm1 $comm2"'//;p}' )
            fi
            subCommand=$( echo $subCommandRaw | command cut -d ' ' -f3- \
                | command sed -r 's/[(<][^)>]*[)>]//g' )
        fi
    fi

    if [[ $cur =~ ^- ]]; then
        _vboxmanage_options
    elif [ $COMP_CWORD -eq 1 ]; then
        _vboxmanage_subcommands
    elif [[ $prev = --ostype ]]; then
        _vboxmanage_ostype
    elif [[ $cur =~ ^\" ]]; then
        _vboxmanage_double_quotes
    elif [[ $subCommandRaw =~ "${prev} <uuid|vmname>" ]]; then
        _vboxmanage_vmname
    elif [[ $COMP_CWORD -eq 4 \
        && ( $prev = --snapshot || $subCommandRaw =~ "${prev} <uuid|snapname>" ) ]]; then
        _vboxmanage_snapname
    else
        _vboxmanage_else_words
    fi

}

_vboxmanage() {
    shopt -u expand_aliases
    set +o histexpand
    set -o noglob

    _vboxmanage_main

    shopt -s expand_aliases
    set -o histexpand
    set +o noglob
}

complete -F _vboxmanage vboxmanage VBoxManage
