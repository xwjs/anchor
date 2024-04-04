#! /usr/bin/bash

# set adaptable color

STORAGE_DIR='/home/cpp'
STORAGE_FILE='.anchor'

declare -A COLOR
declare -A l_ANCHORS
declare -A g_ANCHORS

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    COLOR['YELLOW']='\033[1;33m'
    COLOR['QING']='\033[1;36m'
    COLOR['RED']='\033[01;31m'
    COLOR['GREEN']='\033[01;32m'
    COLOR['BLUE']='\033[01;34m'
    COLOR['NC']='\033[0m'
fi


# copyright

copyright()
{
    printf "${COLOR['RED']}Powered by xwj\u00A9anchor${COLOR['NC']} "
}

# help
help(){
copyright

printf "${COLOR['YELLOW']}help${COLOR['NC']} \n\n"


cat << EOF
command:

    load                         load storage file which path is  STORAGE_DIR/STORAGE_FILE

    list                         show all anchor-path

    goto <anchor>                change directory to anchor points

    add  <anchor> <path> [opt]   add or update anchor-path
                                 if the arg opt  doesnt exist, default visibility is local 

    clr <anchor>                 remove anchor-path

opt:
    -l                           local anchor  (init nothing every time log in)
    -g                           global anchor (available every log in)

EOF
}

# path
parse_path(){
    local path="$1"
    local prefix="$2"

    if [[ "${path}" == '~'* ]]; then
        path="$HOME${path:1}"
    elif [[ "$path" == '.' ]];then
        path="${prefix}"
    elif [[ "$path" != '/'* ]]; then
        path="${prefix}/${path}"
    fi

    echo "$(realpath "$path")"
}

# valid input
is_valid_anchor()
{
    local anchor="$1"

    if [[  "$anchor" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$  ]];then
        return 1
    else
        return 0
    fi
}


is_valid_path()
{
    local path="$1"

    if [ -d "$path" ];then
        return 1
    else
        return 0
    fi
}


is_valid_arg()
{
    local arg="$1"

    if [ "$arg" == '-g' ] || [ "$arg" == '-l' ];then
        return 1
    else 
        return 0
    fi
}

valid()
{
    is_valid_anchor "$1"
    
    if [ "$?" -eq 0 ];then
        return 0
    fi

     is_valid_path "$2"
    
    if [ "$?" -eq 0 ];then
        return 0
    fi

    is_valid_arg "$3"
    
    if [ "$?" -eq 0 ];then
        return 0
    fi

    return 1
}

# implement
load()
{
    copyright
    printf "${COLOR['YELLOW']}load${COLOR['NC']} \n"



    if [ -e "${STORAGE_DIR}/${STORAGE_FILE}" ]; then
        while IFS='=' read -r key value; do

            if [ -z "$key" ] || [ -z "$value" ]; then
                continue
            fi

            value=$(parse_path "$value" "$STORAGE_DIR")    

            if [ -e "$value" ]; then
                g_ANCHORS["$key"]="$value"
            else
                echo "Error:key [${key}]'s path: {$value}  does not exist. Skipping."
            fi
        done < "${STORAGE_DIR}/${STORAGE_FILE}"    

        return 0
    else 
        echo "file:{${STORAGE_DIR}/${STORAGE_FILE} does not exist"
        return 1

    fi
}

clear_anchor()
{
    unset l_ANCHORS[$1]
    unset g_ANCHORS[$1]
    sed "/^$1=/d" "$STORAGE_DIR/$STORAGE_FILE" -i
}


add_anchor()
{
    local anchor="$1"
    local path="$2"
    local -n ANCHORS="${3}"

    if [ -n "${g_ANCHORS[$anchor]}" ] || [ -n "${l_ANCHORS[$anchor]}" ];then
        echo "[$anchor] already existed"
        read -p "Do you want to update it? (y/n): " choice
        case "$choice" in
            y|Y )
                clear_anchor "$anchor" 
                ANCHORS[$anchor]="$path"
                echo "update anchor [$anchor] -> $path"

                return 0
                ;;
            * )
                echo "[$anchor] does not update"
                return 1
                ;;
        esac
    else
        ANCHORS[$anchor]="$path"

        echo "add anchor [$anchor] -> $path"
        return 0
    fi
}

add()
{
    copyright
    printf "${COLOR['YELLOW']}add${COLOR['NC']} \n"

    local anchor="$1"
    local path=$(parse_path "$2" "$(pwd)")
    local arg="$3"

    # size right 2~3
    if [ "$#" -lt 2 ] || [ "$#" -gt 3 ];then
        help
        return 1
    fi

    if [ "$#" -eq 2 ];then
        arg="-l"
    fi

    valid "$anchor" "$path" "$arg"
    if [ "$?" -eq 1 ];then
        if [ "$arg" == '-g' ];then
            add_anchor "$anchor" "$path" g_ANCHORS

            if [ "$?" -eq 0 ];then
                echo "$anchor=$path" >> "${STORAGE_DIR}/${STORAGE_FILE}"
            fi
        else
            add_anchor "$anchor" "$path" l_ANCHORS
        fi
        return 0
    else
        echo "add anchor fail ,please make sure path exist or check help"
        return 1
    fi
}


clr()
{
    if [ -n "$1" ];then
        copyright
        printf "${COLOR['YELLOW']}clear${COLOR['NC']} "

        echo "[$1]"
        clear_anchor "$1"
    else
        help
    fi

}

list()
{
    copyright
    printf "${COLOR['YELLOW']}list${COLOR['NC']}\n"

    max_length=0
    for key in "${!g_ANCHORS[@]}"; do
        if [ ${#key} -gt $max_length ]; then
            max_length=${#key}
        fi
    done
    for key in "${!l_ANCHORS[@]}"; do
        if [ ${#key} -gt $max_length ]; then
            max_length=${#key}
        fi
    done

    if [ "${#g_ANCHORS[@]}" -eq 0 ] && [ "${#l_ANCHORS[@]}" -eq 0 ];then
        printf "No any anchor\n"
        return 1
    fi

    if [ "${#g_ANCHORS[@]}" -ge 1 ]; then
        printf "\n${COLOR['QING']}Global anchor${COLOR['NC']}\n"

        for i in "${!g_ANCHORS[@]}"; do
            printf "${COLOR['QING']}%-${max_length}s${NC} ${COLOR['GREEN']}->${COLOR['NC']} ${COLOR['BLUE']}%s${COLOR['NC']}\n" "$i" "${g_ANCHORS[$i]}"
        done

    fi

    if [ "${#l_ANCHORS[@]}" -ge 1 ]; then
        printf "\nLocal anchor\n"

        for i in "${!l_ANCHORS[@]}"; do
            printf "%-${max_length}s ${COLOR['GREEN']}->${COLOR['NC']} ${COLOR['BLUE']}%s${COLOR['NC']}\n" "$i" "${l_ANCHORS[$i]}"
        done
    fi

    return 0
}

to()
{
    local anchor="$1"

    if [ ! -n "$anchor" ]; then
        help
        return 1
    fi

    if [ -n "${l_ANCHORS[$anchor]}" ]; then
        copyright
        printf "${COLOR['YELLOW']}goto${COLOR['NC']} "
        echo "$anchor"
        cd  "${l_ANCHORS[$anchor]}"
        return 0
    elif [ -n "${g_ANCHORS[$anchor]}" ];then
        copyright
        printf "${COLOR['YELLOW']}goto${COLOR['NC']} "

        echo "$anchor"
        cd "${g_ANCHORS[$anchor]}"
        return 0
    else
        copyright
        echo "[$anchor] does not exist"
        return 1
    fi
}

export -f to
export -f add
export -f load
export -f clr
export -f list
