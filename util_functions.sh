#!/bin/bash

function transfer_source_file() {
    local remote_server=$1
    local remote_userid=$2
    local remote_file=$3

    # Transfer the source file from the remote server to the local machine
    echo "Transferring file from ${remote_server} to local machine..."
    scp "${remote_userid}@${remote_server}:${remote_file}" ./ 
    # Check if the transfer was successful
    check_exit_status "Failed to transfer file from ${remote_server} to local machine."
    echo "File transferred successfully from ${remote_server} to local machine." 
} 


function check_arguments() {
    local expected_args=3
    local actual_args=$1

    if [ $actual_args -ne $expected_args ]; then
        echo "Error: Expected $expected_args arguments, but got $actual_args." >&2
        echo "Usage: $0 <remote_server> <remote_userid> <remote_file>" >&2
        exit 1
    fi

    echo "Correct number of arguments provided."
}


function check_exit_status() {
    local exit_status=$?
    local message=$1

    if [ $exit_status -ne 0 ]; then
        echo "Error: $message" >&2
        exit $exit_status
    fi
}

function get_os() {
    local os=$(uname)
    echo "$os"
}