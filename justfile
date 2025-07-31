# vim: wrap :
default:
    shellcheck --shell bash -x \
    -e SC1090 \
    -e SC2119 \
    -e SC2120 \
    -e SC2128 \
    -e SC2155 \
    -e SC2288 \
    guac libguac.sh
    exit

todo:
    grep -A1 -B1 -e '# TODO*' guac libguac.sh
    cat TODO
    exit

hack:
    vim -S Session.vim

strip-debug:
    sed -i '' '/ansi \-\-blue/d;' ./guac
    sed -i '' '/ansi \-\-blue/d;' ./libguac.sh
