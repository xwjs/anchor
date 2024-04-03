#! /usr/bin/bash -x

STORAGE_DIR='/home/cpp/a/b'
STORAGE_FILE='s.txt'
declare -A ANCHORS
declare -A g_ANCHORS

add(){
    local anchor="$1"
    local path="$2"
    local storage="$3"


    if [ -n "${ANCHORS["$anchor"]}" ]; then
        echo "[$anchor] already exists: ${ANCHORS[$anchor]}"
        read -p "Do you want to update it? (y/n): " choice

        case "$choice" in
            y|Y )
                ANCHORS["$anchor"]="$path"

                if [ "$storage" -eq 1  ];then
                    g_ANCHORS["$anchor"]="$path"
                    echo "$1"="$2" >> ${STORAGE_DIR}/${STORAGE_FILE}
                    echo "[$anchor] -> ${ANCHORS[$anchor]} (global)"
                else
                    if [ -n g_ANCHORS["$anchor"]  ];then
                        unset g_ANCHORS["$anchor"]
                    fi

                    echo "[$anchor] -> ${ANCHORS[$anchor]} (local)"
                fi

                return 0
                ;;
            * )
                echo "[$anchor] does not update"
                return 1
                ;;
        esac
    else
        ANCHORS["$anchor"]="$path"

        if [ "$storage" -eq 1 ];then
            g_ANCHORS["$anchor"]="$path"
            echo "$1"="$2" >> ${STORAGE_DIR}/${STORAGE_FILE}
            echo "[$anchor] -> ${ANCHORS[$anchor]} (global)"
        else
            if [ -n g_ANCHORS["$anchor"]  ];then
                unset g_ANCHORS["$anchor"]
            fi

            echo "[$anchor] -> ${ANCHORS[$anchor]} (local)"
        fi

        return 0
    fi

}

help(){
    echo "help"
}

check_anchor(){
    if [[ -n "$1" ]]; then
        return 0  
    else
        return 1  
    fi
}

# path exist
check_path(){
    if [[ -e "$1"  ]]; then
        return 0 
    else
        echo "path:{$1} does not exist"
        return 1
    fi
}

check_option(){
    if [[ "$1" == "-g" ]]; then
        return 0 
    else
        return 1
    fi
}


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

add_anchor(){

    if [ "$#" -eq 1 ]; then
        check_anchor "$1"
        if [ "$?" -eq 0 ];then
            add "$1" "$(pwd)" 0
        else
            help
            return 1
        fi

    elif [ "$#" -eq 2 ]; then
        local path=$(parse_path "$2" "$(pwd)" )

        check_anchor "$1"
        if [ "$?" -eq 1 ];then
            help
            return 1
        fi

        check_path "$path"
        if [ "$?" -eq 0 ];then
            add "$1" "$path" 0
            return 0
        fi

        check_option "$2"
        if [ "$?" -eq 0 ];then
            add "$1" "$2" 1
            return 0
        fi

        help

        return 1

    elif [ "$#" -eq 3 ]; then

        check_anchor "$1"
        if [ "$?" -eq 1 ];then
            help
            return 1
        fi

        local path=$(parse_path "$2" "$(pwd)" )
        check_path "$path"
        if [ "$?" -eq 1 ];then
            help
            return 1
        fi

        check_option "$3"
        if [ "$?" -eq 1  ];then
            help
            return 1
        fi
        
        add "$1" "$path" 1
        return 0
    else
        help
        return 1
    fi
}


load_anchor(){
    if [ -e "${STORAGE_DIR}/${STORAGE_FILE}" ]; then
        while IFS='=' read -r key value; do
            value=$(parse_path "$value" "$STORAGE_DIR")    

            if [ -e "$value" ]; then
                ANCHORS["$key"]="$value"
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

list_anchor() {
    RED='\033[01;31m'
    GREEN='\033[01;32m'
    BLUE='\033[01;34m'
    NC='\033[0m'

    # align all key
    max_length=0
    for key in "${!ANCHORS[@]}"; do
        if [ ${#key} -gt $max_length ]; then
            max_length=${#key}
        fi
    done

    for i in "${!ANCHORS[@]}"; do
        if [ !  -n "${g_ANCHORS[$i]}"  ];then
           printf "%-${max_length}s ${GREEN}->${NC} ${BLUE}%s${NC}\n" "$i" "${ANCHORS[$i]}"
        fi
    done


    for i in "${!g_ANCHORS[@]}"; do
        printf "${RED}%-${max_length}s${NC} ${GREEN}->${NC} ${BLUE}%s${NC}\n" "$i" "${g_ANCHORS[$i]}"
    done


}

goto_anchor(){
    local anchor="$1"

    if [ -z "$anchor" ]; then
        help
        return 1
    fi

    if [ -n "${ANCHORS[$anchor]}" ]; then
        cd  "${ANCHORS[$anchor]}"
        return 0
    else
        echo "[$anchor] does not exist"
        return 1
    fi

}


export -f  add_anchor
export -f load_anchor
export -f list_anchor
export -f goto_anchor
