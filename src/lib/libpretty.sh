#!/bin/bash
## Begin of libpretty.sh

## Provides general purpose pretty printing function for feedback
## on actions.
##
## Sample of output :
##
##     My Title
##
## My Section
## - My first Elt                   [  OK  ] W
## - My sec Elt            status   [FAILED]
## - My big lengthy desc.. status   [FAILED]
##
##

export SIZE_STATUS=8


## Includes

include color
include common

__esc_char=$(echo -en "\e")
__color_sequence_regex=$(echo -en "\e\[[0-9]+(;[0-9]+)*m")

## Code

##
# usage:  ... | cutline $nb
#
# Returns stdin forced to $nb char long. If stdin was less than $nb it
# is filled with blanks, else it is cut accordingly with appending
# ".." to show that the string was truncated.
#
# Note: this function supports ANSI colors escaping, and do not count
# them as characters.
#
# uses: $GRAY $NORMAL $ansi_color
# depends: cat sed wc printf
#
function cutline() {

    local size content
    local usage_string="usage: $FUNCNAME {nbchar}"

    if test "$#" == "0"; then
        echo "$usage_string" >&2
        return 1
    fi

    size=$1

    ## match one char (followed or not by ansi sequence(s))
    __rchar="(($__color_sequence_regex)*[^$__esc_char]($__color_sequence_regex)*)"
    __rcut="^($__rchar{$[$size - 2]})$__rchar{3}.*\$"
    content="$("$cat" - | sed_compat "s/$__rcut/\1$GRAY../g" )"

    ## size of content wo the ansi color seq
    __size_content=$(echo -n "$content" | \
        sed_compat "s/$__color_sequence_regex//g" | \
        "$wc" -c )

    ## number of invisible chars
    __size_diff=$[ $(echo -n "$content" | wc -c) - $__size_content]

    size=$[$size + $__size_diff]

    content="$(printf "%-${size}s" "$content")$NORMAL"

    echo -en "$content"
}


function Title() {

    local errlvl="$?" usage_string="usage: $FUNCNAME {string}"

    if test "$#" = "0"; then
        echo "$usage_string" >&2
        return 1
    fi

    if test "$ansi_color" != "no"; then
        echo -n "$SET_BEGINCOL"
        test "$__title" && echo -n "$UP$UP$UP"
        test "$__section" && echo -n "$UP$UP"
        test "$__elt" && echo -n "$UP"
    fi

    __spacer="$(echo -n " " | cutline $SIZE_LINE)"
    __content="$(echo -n "    $*" | cutline $SIZE_LINE)"
    __title="$(echo -en "$__spacer\n$__spacer\n${WHITE}    $__content${NORMAL}\n")"

    if test "$ansi_color" != "no"; then
        echo "$SET_BEGINCOL$__title${NORMAL}"
        test "$__section" && echo "$SET_BEGINCOL$__section${NORMAL}"
        test "$__elt" && __Elt_print
    fi

    return "$errlvl"
}


function Section() {

    local errlvl="$?" usage_string="usage: $FUNCNAME {string}"

    if test "$#" = "0"; then
        echo "$usage_string" >&2
        return 1
    fi

    if test "$ansi_color" != "no"; then
        echo -n "$SET_BEGINCOL"
        test "$__section" && echo -n "$UP$UP"
        test "$__elt" && echo -n "$UP"
    fi

    __spacer="$(echo -n " " | cutline $SIZE_LINE)"

    __content="$(echo -n "$*" | cutline $SIZE_LINE)"
    __section="$(echo -en "$__spacer\n${WHITE}$__content${NORMAL}")"

    if test "$ansi_color" != "no"; then
        echo "$SET_BEGINCOL$__section${NORMAL}"
        test "$__elt" && __Elt_print
    fi

    return $errlvl
}


function __Elt_reset() {
    if test "$__elt" -o "$__info" -o "$__status" -o "$__char"; then
        echo -n "$SET_COL_ELT$UP"
    fi
}


function __ListChar_reset() {
    if test "$__elt" -o "$__info" -o "$__status" -o "$__char"; then
        echo -n "$SET_BEGINCOL$UP"
    fi
}


function __Elt_print() {

    if test "$__elt" -o "$__info" -o "$__status" -o "$__char"; then
        [ -z "$__elt" ]      && __elt="$(echo -n "" | cutline $SIZE_ELT)"
        [ -z "$__info" ]     && __info="$(echo -n "" | cutline $SIZE_INFO)"
        [ -z "$__listchar" ] && __listchar="$(echo -n " - "  | cutline $SIZE_LIST)"
        [ -z "$__status" ]   && __status="$(echo -n ""  | cutline $SIZE_STATUS)"
#        [ -z "$__char" ]     && __info="$(echo -n "" | cutline $SIZE_INFO)"
#        echo "$SET_BEGINCOL<$__elt><$__info><$__status><$__char>${NORMAL}"
        echo "$SET_BEGINCOL$__listchar$SEP_LIST_ELT$__elt$SEP_ELT_INFO$__info$SEP_INFO_STATUS$__status$SEP_STATUS_CHAR$__char${NORMAL}"

    fi

}


function Elt() {

    local errlvl="$?" usage_string="usage: $FUNCNAME {string}"

    if test "$#" = "0"; then
        echo "$usage_string" >&2
        return 1
    fi

    test "$ansi_color" != "no" && __Elt_reset

    __content="$(echo -n "$*" | cutline $SIZE_ELT)"
    __elt="$__content"

    test "$ansi_color" != "no" && __Elt_print

    export __elt
    return $errlvl
}


function print_list_char() {

    local errlvl="$?" usage_string="usage: $FUNCNAME {string}"

    if test "$#" = "0"; then
        echo "$usage_string" >&2
        return 1
    fi

    test "$ansi_color" != "no" && __ListChar_reset

    __content="$(echo -n "$*" | cut -c -$SIZE_LIST)"
    __listchar="$__content"

    test "$ansi_color" != "no" && __Elt_print

    export __listchar

    return $errlvl
}


function Comment() {
    print_list_char " $GRAY#$NORMAL "
    Elt "$*"
    Feed
}


function Feed() {

    local errlvl="$?" usage_string="usage: $FUNCNAME"

    if test "$#" -gt "0"; then
        echo "$usage_string" >&2
        return 1
    fi

    if test "$ansi_color" == "no"; then
        [ "$__title"   ] && echo "$__title"
        [ "$__section" ] && echo "$__section"

        if test "$__elt" -o "$__info" -o "$__status" -o "$__char"; then
            [ -z "$__info" ]     && __info="$(echo -n "" | cutline $SIZE_INFO)"
            [ -z "$__elt" ]      && __elt="$(echo -n ""  | cutline $SIZE_ELT)"
            [ -z "$__listchar" ] && __listchar="$(echo -n " - "  | cutline $SIZE_LIST)"
            [ -z "$__status" ] && __status="$(echo -n ""  | cutline $SIZE_STATUS)"

                  ## XXXvlab: what about $__status and $__char ?

            echo "$__listchar$SEP_LIST_ELT$__elt$SEP_ELT_INFO$__info$SEP_INFO_STATUS$__status$SEP_STATUS_CHAR$__char"
        fi
    fi

    unset __listchar __title __section __elt __info __char __status
    return $errlvl
}


function BreakFeed() {
    local errlvl="$?"
    test "$errlvl" -ne "0" && echo
    return $errlvl
}


function Feedback() {
    local errlvl="$?" usage_string="usage: $FUNCNAME [{fail-label} [{ok-label}  [{fail-string} [{ok-string}]]]]"

    if test "$#" -gt "5"; then
        echo "$usage_string" >&2
        return 1
    fi

    if test "$errlvl" = "0" ; then
        test  "$4" && print_info "$4"
        test  "$4" && print_status "$2" || print_status success
    else
        test  "$3" && print_info "$3"
        test  "$1" && print_status "$1" || print_status failure
    fi

    Feed
    return $errlvl
}


##
# Outputs the given string to the info-field
#
# Note : preserves the errlvl
#
# @param $* message to print in the info field.
function print_info() {

    local errlvl="$?" usage_string="usage: $FUNCNAME {string}"

    if test "$#" = "0"; then
        echo "$usage_string" >&2
        return 1
    fi

    test "$ansi_color" != "no" && __Elt_reset

    __content=$(echo -n "$*" | cutline "$SIZE_INFO")

    # Note that GRAY and NORMAL are set only if ansi_color != no
    __info="$GRAY$__content$NORMAL"

    test "$ansi_color" != "no" && __Elt_print

    return $errlvl
}


function print_info_char() {

    local errlvl="$?" usage_string="usage: $FUNCNAME {string}"

    if test "$#" = "0"; then
        echo "$usage_string" >&2
        return 1
    fi

    test "$ansi_color" != "no" && __Elt_reset

    __char="${WHITE}$(echo $* | "$cut" -c 1)${NORMAL}"

    test "$ansi_color" != "no" && __Elt_print

    return $errlvl

}


function set_col() {

    local usage_string="usage: $FUNCNAME {number}"

    if test "$#" != "1"; then
        echo "$usage_string" >&2
        return 1
    fi

    echo -en "\\033[${1}G"

}


function print_status() {

    local usage_string="usage: $FUNCNAME {success|warning|failure|on|off|noop} {short|long} {string}" type_method

    if test "$#" = "0"; then
        echo "$usage_string" >&2
        return 1
    fi

    if test "$2" != "short" &&
        test "$2" != "long" &&
        test "$#" != "1"; then

        echo "$FUNCNAME: '$2' is a bad second argument, try : short long"
        echo "$usage_string" >&2
        return 1
    fi

    type_method=$2

    test "$#" = "1" && type_method="long"

    test "$ansi_color" != "no" && __Elt_reset

    case "$1" in
        success)
            if test "$type_method" = "long"; then
                __status="[${SUCCESS}  OK  ${NORMAL}]"
            else
                echo -n "${SUCCESS}"
                shift; shift;
                echo -n "$*${NORMAL}"
            fi
            ;;
        warning)
            if test "$type_method" = "long"; then
                __status="[${WARNING} ATTN ${NORMAL}]"
            else
                echo -n "${WARNING}"
                shift; shift;
                echo -n "$*${NORMAL}"
            fi
            ;;
        failure)
            if test "$type_method" = "long"; then
                __status="[${FAILURE}FAILED${NORMAL}]"
            else
                echo -n "${FAILURE}"
                shift; shift;
                echo -n "$*${NORMAL}"
            fi
            ;;
        on)
            if test "$type_method" = "long"; then
                __status="[${ON}  ON  ${NORMAL}]"
            else
                echo -n "${ON}"
                shift; shift;
                echo -n "$*${NORMAL}"
            fi
            ;;
        off)
            if test "$type_method" = "long"; then
                __status="[${OFF}  OFF ${NORMAL}]"
            else
                echo -n "${OFF}"
                shift; shift;
                echo -n "$*${NORMAL}"
            fi
            ;;
        noop)
            if test "$type_method" = "long"; then
                __status="[${NOOP}  NA  ${NORMAL}]"
            else
                echo -n "${NOOP}"
                shift; shift;
                echo -n "$*${NORMAL}"
            fi
            ;;
        *)
            echo "$FUNCNAME: '$1' is a bad first argument."
            echo $usage_string
            return 1
            ;;
    esac

    test "$ansi_color" != "no" && __Elt_print
    return 0
}


function Wrap() {

    local quiet desc errlvl

    quiet=false
    if [ "$1" == "-q" ]; then
        quiet=
        shift
    fi

    desc=""
    if [ "$1" == "-d" ]; then
        desc="$2"
        shift
        shift
    fi

    if test -z "$*"; then
        code=$("$cat" -)
        [ "$quiet" == false -a -z "$desc" ] &&
        print_error "no description for warp command"
    else
        code="$*"
        test -z "$desc" && desc="$*"
    fi

    [ "$quiet" ] && Elt "$desc"
    [ "$quiet" ] && print_info_char "W"

    md5="$(echo "$code" | md5_compat)"
    tmp_wrap="/tmp/wrap.$md5.$$.tmp"

    ( echo "$code" | bash > "$tmp_wrap" 2>&1 )

    errlvl="$?"
    if [ "$errlvl" == "0" ]; then
        rm "$tmp_wrap"
        [ "$quiet" ] && print_status success && Feed
        return 0
    fi

    [ "$quiet" ] && print_status failure && Feed

    echo "${RED}*****${WHITE} ERROR in wrapped command:${NORMAL}"
    echo "${YELLOW}*****${WHITE} code:${NORMAL}"
    echo "$code"
    echo "${YELLOW}>>>>> ${WHITE}Log info follows:$NORMAL "
    "$cat" "$tmp_wrap"
    echo "${YELLOW}<<<<< ${WHITE}End Log."
    echo "${YELLOW}*****$NORMAL errorlevel was : ${WHITE}$errlvl${NORMAL}"

    return $errlvl

}


## Export all function of this file

depends wc sed cat cut egrep grep

__funcnames=$(cat "$BASH_SOURCE" | "$egrep" "^ *function +\w+ *\(\)" | sed_compat 's/^ *function (.+)\(\).*/\1/g' | xargs echo)
all_functions=$(compgen -A function)
for __fname in $__funcnames; do
    ## export only declared functions...
    if echo "$all_function" | "$grep" "$__fname" > /dev/null; then
        export -f $__fname
    fi
done


## End of libpretty.sh
