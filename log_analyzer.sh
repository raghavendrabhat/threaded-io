#!/bin/bash

set -e

function _init ()
{
    if [ $# -ne 1 ]; then
        echo "usage: log_analyzer.sh <log_file_path>";
        exit 2;
    fi

    log_file=$1;

}

function analyze ()
{
    # Do not consider the volfile section or the crash backtrace of the
    # log file. This can be done by just extracting the remaining part,
    # which can be identified by checking the first character for '['
    grep "^\[" $log_file > /tmp/tmp_log_file;

    cat /tmp/tmp_log_file | cut -d ']' -f 2 | cut -d ':' -f3 | sort -n > /tmp/functions_file;

    cat /tmp/tmp_log_file | cut -d ']' -f 2 | cut -d ':' -f3 | sort -n | uniq > /tmp/uniq_function;

    for i in $(cat /tmp/uniq_function)
    do
        count=$(grep $i /tmp/functions_file | wc -l)
        echo "$i:$count"
    done

    #grep  "time of crash:" $log_file 2>/dev/null;
}

function cleanup ()
{
    rm -f /tmp/functions_file;
    rm -f /tmp/uniq_function;
    rm -f /tmp/tmp_log_file;
}

function main ()
{
    cleanup;
    analyze;
    cleanup;
}

_init "$@" && main "$@"
