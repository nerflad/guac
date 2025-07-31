# guac/libguac.sh
# © 2024 Eric Bailey - MIT
# vim: foldmethod=indent :

# ~ msg ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function GUACMSG_BRACE () {
    brace=$(for i in $(seq 42); do printf '~'; done);
    case "$1" in
        open  ) ansi --faint "|${brace}";;
        close ) ansi --faint " ${brace}|";;
    esac
}

function GUACMSG_HELP () {
cat << EOF
     $(ansi --green "🥑      git under a comma")
     $(GUACMSG_BRACE open)
     $(ansi --bold  ", -b    bind alias e.g:  , -b \",ls\" \"git status\"")
     $(ansi --bold  ", -e    edit source")
     $(ansi --bold ", -h    display help")
     $(ansi --bold ", -i    install (dump symlinks to specified dir)")
     $(ansi --bold  ", -l    show aliases")
     $(ansi --bold ", -u    uninstall")
     $(ansi --bold  ",       git \$argv || git status")
     $(GUACMSG_BRACE close)
EOF
}

function GUACMSG__LONGHELP_FORMAT () { local line=$1
    local padding=5;
    local formatwidth=$((COLUMNS / 10));

    local col1=$(cut -d' ' -f1  < <(echo "$line"))
    local col2=$(cut -d' ' -f2- < <(echo "$line"))

    for i in $(seq $padding); do printf ' '; done
    ansi -n --green  "$col1"
    for i in $(seq $formatwidth); do printf ' '; done
    ansi --faint     "$col2"
}

function GUACMSG_LONGHELP () {
    # print the normal help message followed by all the functions at the end of this file
    GUACMSG_HELP
    while read -r line; do
        GUACMSG__LONGHELP_FORMAT "$line"; done < <(sed -f - "$GUACLIB" << EOF
        1,/#\{80\}/d
        s/function //g
        s/() { //g
        s/; }//g
        s/ \"\$\@\"//g
        /^#/d
EOF
    );
    # print aliases if there are any (guac -l)
    GUAC_LISTUSRFUNCS
}

function GUACMSG_NOREPO () { GUAC_FILTERMSG "$FUNCNAME" || (\
    ansi -n --green "[guac: ] "
    ansi --normal "Not a git repository."
    GUACMSG_SUPPRESS
)}

function GUACMSG_PATH () { GUAC_FILTERMSG "$FUNCNAME" || (\
    grep -q -F -- "$GUACUSRBIN" <<< "$PATH" || (
        ansi --faint "$GUACUSRBIN isn't on your PATH."
        ansi --faint "If you don't want to pollute your path, why use guac? 🥑"
        GUACMSG_SUPPRESS
    );
)}

function GUACMSG_SUPPRESS () { GUAC_FILTERMSG "$FUNCNAME" || (\
    [ -n "$__SUPPRESS_NOTIFIED" ] && (
         ansi --green "[To suppress these messages, check $GUACRC]"
         __SUPPRESS_NOTIFIED=1;
     );
)}

# ~ fails ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function GUACFAIL_DIR () {
    ansi --red "[guac: ] failed to read/create $1"
    ansi --red "Check permissions or try manually creating $1"
    exit 255
}

function GUACFAIL_SOURCE () {
    ansi --red "[guac: ] failed to source usrfunc."
    exit 255
}

function GUACFAIL_FUNC () {
    ansi --red "[guac: ] no function $1 exists."
    exit 255
}

# ~ big functions ~~~~~~~~~~~~~~~~~~~~~~~

function GUAC_BIND () {
    shift
    if [ -z "$2" ]; then
        # TODO: usage
       GUACMSG_HELP
       exit 1
    else
    # write the new alias as a bash function to new file in GUACUSRFUNC.
    # create symlink to guac executable with new function's name in GUACUSRBIN.
    # guac sources usrfuncs beginning with , on startup.
    # if GUACUSRBIN is on path (and a symlink matching the usrfunc exists),
    # the function will be linked and called by guac at runtime.
       def1="function $1 () { "
       shift;
       # shellcheck disable=SC2124
       def2="$def1""$@ \"\$@\"; };"
       newfuncname="$(echo "${def2#function }" | awk -F\  '{print $1}')"
       filename="$GUACUSRFUNC"/"$newfuncname"
       linkname="$GUACUSRBIN"/"$newfuncname"
       if [ -e "$filename" ]; then
           ansi --red "🥑 File $filename exists."
           exit 1
        fi
        echo "$def2" >> "$filename" && (\
            ansi --green "🥑 $filename";
        );
        if ! [ -e "$linkname" ]; then
            ln -s "${GUACDIR:?}/guac" "$linkname"
            ansi --faint "Created symlink in $GUACUSRBIN"
        fi
    fi
}

function GUAC_EDITUSRFUNC () { local func="$1";
    if [ -z "$func" ]; then
        "$EDITOR" -O "$GUACBIN/," "$GUACLIB"
        # prevent reopening the editor after shift
        return
    fi
    for file in "${!__USRFUNC[@]}"; do
        # shellcheck disable=SC2046,SC2086
        if [ "$func" == "$(basename $file)" ]; then
            "$EDITOR" "$file"
            return
        fi
    done
    # Fallthrough: edit new func
    "$EDITOR" "$GUACUSRFUNC/$func"
}

function GUAC_FILTERMSG () {
    [ $((!"${#GUAC__SUPPRESS[@]}")) = 0 ] && (
      for msg in ${GUAC__SUPPRESS}; do
        [ "$msg" == "$1" ] && return 1;
      done
    );#else ↓
    return 0;
}

function GUAC_INITDIRS () {
    for dir in "$GUACPRIV" "$GUACUSRBIN" "$GUACUSRFUNC"; do
        if ! [ -e "$dir" ]; then
            mkdir "$dir" || GUACFAIL_DIR "$dir"
        fi
    done
}

function GUAC_INSTALL () {
    [ -d "$1" ] || (
        echo 🥑 Please specify a valid directory.
        exit 1
    );
    guaclinks="$1"
    for symlink in $(compgen -A function | grep -e ','); do
        ln -s "${GUACDIR:?}/guac" "$guaclinks"/"$symlink" && (
          GUAC_FILTERMSG "GUAC_INSTALL" || (
            GUAC_FILTERMSG "GUAC_INSTALL_SMOL" || ( ansi --green 🥑 "$symlink")
          ) && (
            ansi -n --green "$symlink "
          )
        )
    done
    # pollute home directory
    echo # \n
    [ -e "$GUACRC" ] || (
        [ -d "$GUACPRIV" ] || (mkdir -p "$GUACPRIV");
        cp "${GUACDIR:?}/guacrc" "$GUACRC" && ansi --green "Created $GUACRC"
    );
    GUAC_FILTERMSG "GUAC_INSTALL_SMOL" || ( GUACMSG_HELP );
}

function GUAC_LISTUSRFUNCS () {
    if [ $(("${#__USRFUNC[@]}")) = 0 ]; then
        return
    else
        ansi --faint --blue "Found guac usrfuncs:"
    fi
    for func in "${!__USRFUNC[@]}"; do
        ansi -n --faint "$(dirname $func)"/
        ansi --green "$(basename $func)"
    done
    ansi --faint --blue "🥑 drop them in ${EDITOR} with \`, -e \$FUNCNAME\`"
}

function GUAC_INITUSRFUNCS () {
    # modifies global array of filenames and link targets
    filelist=$(find "$GUACUSRFUNC" -type f | grep -e ',.*')
    if [ $((${#filelist[@]})) -gt 0 ]; then
        for file in $filelist; do
            linkpath="$GUACUSRBIN"/$(basename "$file")
            __USRFUNC["$file"]="$linkpath"
        done
    fi
    # create symlinks in guacusrbin if they do not exist
    for file in "${!__USRFUNC[@]}"; do
        linkpath=${__USRFUNC[$file]}
        if ! [ -e "$linkpath" ]; then
            ansi --faint "ln -s ${GUACDIR:?}/guac $linkpath"
            ln -s "${GUACDIR:?}/guac" "$linkpath" && (\
                ansi --green "🥑 linked new saved function: $linkpath"
            );
        fi
     done
}

function GUAC_UNINSTALL () {
    guaclinks=()
    for i in $(find "$GUACBIN" -type l | grep -e ',.*'); do
        guaclinks+=("$i")
    done
    ansi --green --bg-black "$(GUACMSG_BRACE open)"
    ansi --green --bg-black "Delete guac symlinks (preserving guacrc and usrfuncs)?: "
    read -r -p "$(ansi --green --bg-black 🥑 Continue \(Y\/n\)\: )" choice
    ansi --green --bg-black "$(GUACMSG_BRACE close)"
    case "$choice" in
        *   ) ;;
        n|N ) exit 0;;
    esac
    for i in "${guaclinks[@]}"; do
        # shellcheck disable=SC2005,SC2086
        rm "$i" && ( GUAC_FILTERMSG "$FUNCNAME" || (
            echo "$(ansi --red $i)"
        ));
    done
    read -r -p "$(ansi --green --bg-black 🥑 Delete ${GUACRC} \(y\/N\)\: )" choice
    case "$choice" in
        y|Y ) echo rm "${GUACRC}";;
        *   ) ;;
    esac
}

function GUAC_REPOCHECK () {
    [ -n "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ] || return 128;
    return 0
}


# ~ pile of ugly functions that should be refactored ~~~~

function __branch_or_checkout_existing () {
    # shellcheck disable=SC2143
    # the linter complains about grep -q
    # but to wait for the subshell to
    # return is more reliable 🙃
    if [ -z "$1" ]; then
        git branch
        exit 0
    elif [ $# == 1 ] && [ -n "$(git branch | grep -e "$1")" ]; then
            git checkout "$1"
        else
            git branch "$@"
    fi;
}

# ~ self ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ,      () {
    if [ -z "$1" ]; then
        if ! GUAC_REPOCHECK; then
            GUACMSG_HELP
            exit 128
        fi
        git status
    else
        git "$@"
    fi
}

function guac   () { , "$@"; }


# ~ user interface ~~~~~~~~~~~~~~~~~~~~~~~
# everything below this line is also the input for GUACMSG_LONGHELP
################################################################################
function ,,     () {    git status "$@"; }
function ,,,    () {    GUACMSG_LONGHELP; exit 0; }

function ,a     () {    git add "$@"; }
function ,a.    () {    ,a . ; }
function ,au    () {    ,a --update "$@"; }
function ,auc   () {    ,au && , commit "$@"; }
function ,aucm  () {    ,auc -m "$@"; }

function ,b     () {    __branch_or_checkout_existing "$@"; }
function ,bd    () {    ,b -d "$@"; }

function ,c     () {    git commit "$@"; }
function ,cm    () {    ,c -m "$@"; }

function ,clf   () {    git clean -f "$@"; }

function ,d     () {    git diff "$@"; }
function ,ds    () {    ,d --staged "$@"; }

function ,guac  () {    ,auc  "$@"; }
function ,guacm () {    ,aucm "$@"; }

function ,l     () {    git log "$@"; }
function ,la    () {    ,l --abbrev "$@"; }
function ,ll    () {    ,l --oneline "$@"; }
function ,log   () {    ,l "$@"; }

function ,m     () {    git merge "$@"; }

function ,v     () {    git mv "$@"; }

function ,o     () {    git remote -v "$@"; }
function ,oa    () {    ,o add "$@"; }
function ,oao   () {    ,oa origin "$@"; }
function ,or    () {    ,o remove "$@"; }

function ,pull  () {    , pull "$@"; }
function ,push  () {    , push "$@"; }

function ,r     () {    , reset "$@"; }

function ,s     () {    , stash "$@"; }
function ,pop   () {    , stash pop "$@"; }
function ,put   () {    , stash push "$@"; }

