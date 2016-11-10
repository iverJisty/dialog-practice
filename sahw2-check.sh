#!/bin/sh

testcase(){
    path="/tmp/$2"
    mkdir -p "$path"
    cd "$path"
    echo "Downloading $2"
    if [ -n "$linux" ] ; then
        wget -q "$1" -O - | tar xz
    else
        wget -q "$1" -O - | tar jxf -
    fi
    echo "======================"
    $cmd
    echo "======================"
    echo "Press Enter to Continue.."
    read line
}

specialcase(){
    path="/tmp/$2"
    mkdir -p "$path"
    cd "$path"
    echo "Downloading $2"
    if [ -n "$linux" ] ; then
        wget -q "$1" -O - | tar xz
    else
        wget -q "$1" -O - | tar jxf -
    fi
    mkfifo tempfifo 2>/dev/null
    ln -s /etc/passwd thesecret 2>/dev/null
    echo "======================"
    $cmd
    echo "======================"
    echo "Press Enter to Continue.."
    read line
}
linux=$(uname | grep "inux")
cmd=$(realpath "$1")
testcase "https://github.com/Thomas-Tsai/partclone/archive/0.2.89.tar.gz" "partclone.0.2.89"
testcase "https://github.com/Gallopsled/pwntools/archive/3.1.1.tar.gz" "pwntool.3.1.1"
testcase "https://github.com/Z3Prover/z3/archive/z3-4.4.1.tar.gz" "z3.4.4.1"
specialcase "https://github.com/tjjh89017/ezio/archive/v0.2.tar.gz" "ezio.0.2"

