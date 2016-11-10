#!/bin/sh



showBK(){

    counter=3
    title="1 Add_a_bookmark
    2 Delete_a_bookmark
    "
    bk=`cat $DIR/.mybrowser/bookmark`
    outBK=$title
    for i in $bk
    do
        outBK="$outBK$counter $i
        "
        counter=$((counter+1))
    done

    if [ $1 != 1 ]; then
        outBK="$outBK$counter $2"
    else
        counter=$((counter-1))
    fi


    return $counter

}

getAllLink() {
    str=""
    if ! echo $1 | egrep -q '/$'; then
        str=$1'/'
    else
        str=$1
    fi

    # Get all links
    tmp="$(curl -s -L $str | grep -Eo '<a href=(.*)>' | sed -E 's/<a href="(.*)">(.*)/\1/g')"
    final=""
    

    # Find if start with relative(/) path.
    for i in $tmp
    do
        #( echo "$i" | grep -Eq '^/')
        #if [ $? == 1  ]; then
        #    final=$final$i$'\n'
        #else
        #    # haven't done "../" expression
        #    final=$final$1$i$'\n'
        #fi

        if echo $i | egrep -q '^https?://'; then            # Case : http://www.google.com
            final=$final$i$'\n'
        elif echo $i | egrep -q '^[a-zA-Z0-9]'; then        # Case : sap/123.html
            final=$final$str$i$'\n'
        elif echo $i | egrep -q '^/'; then                  # Case : /sap/123.html
            i=$(echo $i | sed 's/^\///g')
            final=$final$str$i$'\n'
        elif echo $i | egrep -q '^\.\.'; then                 # Case : ../../../ggggg.html
            back=$str
            while echo $i | egrep -q '^\.\.'; do
                i=$(echo $i | sed 's/^\.\.//g')
                back=$(echo $back | sed 's/\(.*\)\/\(.*\)\//\1\//')
            done
            if [ "$i" == "/" ]; then
                final=$final$back$'\n'
            else
                final=$final$back$i$'\n'
            fi
        fi
    done

    # Create the menu
    line=$(printf "$final" | wc -l)
    final=$(printf "$final" | awk 'BEGIN { seq=1 } { print seq, $1 ; seq++}')

    result=$(dialog --menu "Links" 200 100 $line $final 2>&1 1>&3)

    # Get the link
    match=0
    for i in $final
    do
        if [ $match == 1 ]; then
            result=$i
            break
        fi

        if [ "$i" == "$result" ]; then
            match=1
        fi
    done
}

parseUri(){

    # If uri
    ( echo ${1} | grep -Eq '(http|https)://[0-9a-zA-Z./=_?-]*' ) && return 1

    # If cmd
    ( echo ${1} | grep -Eq '^/' ) && return 2

    # If shell cmd
    ( echo ${1} | grep -Eq '^!' ) && return 3

    return 0
}

executeCmd(){


    if [ "$1" == "/S" ] || [ "$1" == "/source" ]; then

        # Verify if argument is url
        parseUri ${2}
        if [ "$?" != "1" ]; then
            return 1
        fi

        dialog --msgbox "$(curl -s -L $2)" 200 100

    elif [ "$1" == "/L" ] || [ "$1" == "/link" ]; then

        # Verify if argument is url
        parseUri ${2}
        if [ "$?" != "1" ]; then
            return 1
        fi

        # Select all link in menu
        getAllLink $2

        # Go to target link
        dialog --msgbox "$(w3m -dump $result)" 200 100

    elif [ "$1" == "/D" ] || [ "$1" == "/download" ]; then

        # Verify if argument is url
        parseUri ${2}
        if [ "$?" != "1" ]; then
            return 1
        fi

        # Select all link in menu
        getAllLink $2

        # Check '~/Downloads' exist, if not , create it
        if [ ! -d "$DIR/Downloads" ]; then
            mkdir $DIR/Downloads
        fi

        # Download target link to '~/Downloads/'
        ( cd $DIR/Downloads; curl -O $result )


    elif [ "$1" == "/B" ] || [ "$1" == "/bookmark" ]; then


        # Verify if argument is url
        just_show=0
        parseUri ${2}
        if [ "$?" != "1" ]; then
            just_show=1
        fi

        showBK $just_show $2
        counter=$?
        result=$(dialog --menu "Bookmarks" 200 100 $counter $outBK 2>&1 1>&3)

        if [ $just_show != 1 ]; then
            touch $DIR/.mybrowser/bookmark
            echo $2 >> $DIR/.mybrowser/bookmark
        fi

        if [ $result == 1 ]; then
            new_url=$(dialog --inputbox "Enter the url : " 8 40  2>&1 1>&3)
            executeCmd $1 $new_url
        elif [ $result == 2 ]; then
            item=$(dialog --inputbox "Enter the number to delete : " 8 40  2>&1 1>&3)
            item=$((item-2))
            sed "$item d" $DIR/.mybrowser/bookmark > $DIR/.mybrowser/.tmp
            cat $DIR/.mybrowser/.tmp > $DIR/.mybrowser/bookmark

            executeCmd $1
        else
            target_url=`sed -n "$((result-2))p" $DIR/.mybrowser/bookmark`
            dialog --msgbox "$(w3m -dump $target_url)" 200 100
        fi

    elif [ "$1" == "/H" ] || [ "$1" == "/help" ]; then
        dialog --msgbox "`cat $DIR/.mybrowser/help`" 200 100
    fi


}

# Var
LOOP="1"
result=""
outBK=""
DIR=`pwd`
exec 3>&1;

dialog --title "Terms"  --yesno "$(cat $DIR/.mybrowser/userterm)" 200 100

if [ "$?" != "0" ]
then
    dialog --title "Apology" --msgbox "Bye bye." 5 30
    exit
fi

while [ $LOOP == "1" ]; do

    result=$(dialog --inputbox "Enter the url : " 8 40  2>&1 1>&3 )

    if [ "$?" != "0" ]
    then
        exit
    fi

    # echo "Result : " $result

    parseUri $result
    code=$?

    if [ "$code" == 1 ]; then
#        result=$(echo $result | sed 's/\(.*\):\/\/\(.*\)/\2/g')
        dialog --msgbox "$(w3m -dump $result)" 200 100
    elif [ "$code" == 2 ]; then
        cmd=$(echo $result | cut -d ' ' -f 1)
        arg=$(echo $result | cut -d ' ' -f 2)
        executeCmd $cmd $arg
    elif [ "$code" == 3 ]; then
        cmd=`echo $result | cut -c 2-`
        dialog --msgbox "`$cmd`" 200 100
    else
        dialog --msgbox "Invalid Input. \nTry /H for help messages." 200 100

    fi



done



