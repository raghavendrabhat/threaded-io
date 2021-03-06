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

function analyze_functions ()
{
    # Do not consider the volfile section or the crash backtrace of the
    # log file. This can be done by just extracting the remaining part,
    # which can be identified by checking the first character for '['

    type=$(file $log_file | cut -f 2 -d ":" | cut -f 2 -d " ");
    if [ $type == "directory" ]; then
	echo "given argument $log_file is $type";
	return;
    elif [ $type == "empty" ]; then
	echo "given argument $log_file is $type";
	return;
    fi

    if [ $type == "ASCII" ]; then
	total_lines=$(grep "^\[" $log_file | wc -l | cut -f1 -d' ');
	grep "^\[" $log_file | cut -d ']' -f 2 | cut -d ':' -f3 | sort -n | tee /tmp/functions_file | uniq > /tmp/uniq_function;

	grep -E ' E | W ' $log_file | cut -d ']' -f 2 | cut -d ':' -f3 | sort -n | tee /tmp/error_functions_file | uniq > /tmp/error_uniq_function;
    fi

    if [ $type == "bzip2" ]; then
	total_lines=$(bzcat $log_file | grep "^\[" | wc -l | cut -f1 -d' ');
	bzcat $log_file | grep "^\[" | cut -d ']' -f 2 | cut -d ':' -f3 | sort -n | tee /tmp/functions_file | uniq > /tmp/uniq_function;

	bzcat $log_file | grep -E ' E | W ' | cut -d ']' -f 2 | cut -d ':' -f3 | sort -n | tee /tmp/error_functions_file | uniq > /tmp/error_uniq_function;
    fi

    if [ $type == "gzip" ]; then
	total_lines=$(zcat $log_file | grep "^\[" | wc -l | cut -f1 -d' ');
	zcat $log_file | grep "^\[" | cut -d ']' -f 2 | cut -d ':' -f3 | sort -n | tee /tmp/functions_file | uniq > /tmp/uniq_function;

	zcat $log_file | grep -E ' E | W ' | cut -d ']' -f 2 | cut -d ':' -f3 | sort -n | tee /tmp/error_functions_file | uniq > /tmp/error_uniq_function;
    fi

    printf "Number\tPercentage\tFunction\n";

    (for i in $(cat /tmp/uniq_function)
    do
	count=$(grep $i /tmp/functions_file | wc -l);
	percent=$(printf "%.2f" $(echo "($count / $total_lines) * 100" | bc -l));
	printf "%d\t%s\t %s\n" $count $percent $i;
    done) | sort -nr

    echo -e -n "\n";

    echo  "========= Error Functions ========";
    echo -e -n "\n";
    (for i in $(cat /tmp/error_uniq_function)
    do
	count=$(grep $i /tmp/error_functions_file | wc -l);
	percent=$(printf "%.2f" $(echo "($count / $total_lines) * 100" | bc -l));
	printf "%d\t%s\t%s\n" $count $percent $i;
    done) | sort -nr
    #grep  "time of crash:" $log_file 2>/dev/null;
}

function analyze_msgid ()
{
    # Do not consider the volfile section or the crash backtrace of the
    # log file. This can be done by just extracting the remaining part,
    # which can be identified by checking the first character for '['

    type=$(file $log_file | cut -f 2 -d ":" | cut -f 2 -d " ");
    if [ $type == "directory" ]; then
	echo "given argument $log_file is $type";
	return;
    elif [ $type == "empty" ]; then
	echo "given argument $log_file is $type";
	return;
    fi

    if [ $type == "ASCII" ]; then
	total_lines=$(grep "^\[" $log_file | grep "MSGID" | wc -l | cut -f1 -d' ');
	grep "MSGID" $log_file | cut -d ']' -f 2 | cut -d ':' -f 2 | cut -d ' ' -f 2 | sort -n | tee /tmp/msgid_file | uniq > /tmp/msgid;

	grep -E ' E | W ' $log_file  | grep "MSGID" | cut -d ']' -f 2 | cut -d ':' -f 2 | cut -d ' ' -f 2 | sort -n | tee /tmp/error_msgid_file | uniq > /tmp/error_msgid;
    fi

    if [ $type == "bzip2" ]; then
	total_lines=$(bzcat $log_file | grep "^\[" | wc -l | cut -f1 -d' ');
	bzcat $log_file | grep "MSGID" | cut -d ']' -f 2 | cut -d ':' -f 2 | cut -d ' ' -f 2 | sort -n | tee /tmp/msgid_file | uniq > /tmp/msgid;

	bzcat $log_file | grep -E ' E | W ' | cut -d ']' -f 2 | grep MSGID | cut -d ':' -f 2 | cut -d ' ' -f 2 | sort -n | tee /tmp/error_msgid_file | uniq > /tmp/error_msgid
    fi

    if [ $type == "gzip" ]; then
	total_lines=$(zcat $log_file | grep "^\[" | wc -l | cut -f1 -d' ');
	zcat $log_file | grep "MSGID" | cut -d ']' -f 2 | cut -d ':' -f 2 | cut -d ' ' -f 2 | sort -n | tee /tmp/msgid_file | uniq > /tmp/msgid;

	zcat $log_file | grep -E ' E | W ' | cut -d ']' -f 2 | grep MSGID | cut -d ':' -f 2 | cut -d ' ' -f 2 | sort -n | tee /tmp/error_msgid_file | uniq > /tmp/error_msgid;
    fi

    printf "\nNumber\tPercentage\tMSGID\n";

    (for i in $(cat /tmp/msgid)
    do
	count=$(grep $i /tmp/msgid_file | wc -l);
	percent=$(printf "%.2f" $(echo "($count / $total_lines) * 100" | bc -l));
	printf "%d\t%s\t %s\n" $count $percent $i;
    done) | sort -nr

    echo -e -n "\n";

    echo  "========= Error MSGIDs ========";
    echo -e -n "\n";
    (for i in $(cat /tmp/error_msgid)
    do
	count=$(grep $i /tmp/error_msgid_file | wc -l);
	percent=$(printf "%.2f" $(echo "($count / $total_lines) * 100" | bc -l));
	printf "%d\t%s\t%s\n" $count $percent $i;
    done) | sort -nr
    #grep  "time of crash:" $log_file 2>/dev/null;
}

function cleanup ()
{
    rm -f /tmp/functions_file;
    rm -f /tmp/uniq_function;

    # removing the files containg about error and warning logs
    rm -f /tmp/error_functions_file;
    rm -f /tmp/error_uniq_function;

    rm -f /tmp/msgid_file;
    rm -f /tmp/error_msgid

    rm -f /tmp/error_msgid_file;
    rm -f /tmp/msgid;
}

function main ()
{
    cleanup;
    analyze_functions;
    analyze_msgid;
    cleanup;
}

_init "$@" && main "$@"
