#!/bin/bash

function _init ()
{
    set -u;

    # Can be made to rename the entries in the present working directory
    # if no argument is given. But the script will also be renamed because
    # of that which we dont want.
    # Can be enhanced later to accomplish the above behavior.

    if [ $# -ne 1 ]; then
        echo "usage: ./rename_files.sh <path to the directory>";
        return 1;
    fi

    rename_path=$1;
    if [ ! -d $rename_path ]; then
        echo "given destination $rename_path is not a directory";
        return 1;
    fi
}

function rename_entries ()
{
    local dest=$1;

    for entry in $(ls $dest)
    do
        mv $dest/$entry $dest/$entry"_okpa"
    done

    return;
}

function main ()
{
    echo $rename_path && sleep 2;
    echo "renaming the entries in the directory $rename_path....."

    rename_entries $rename_path;

    return;
}

_init "$@" && main "$@"