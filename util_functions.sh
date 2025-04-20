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

function convert_gender_field() {
    local input_file=$1
    local field_number=$2

    # create a temp file to store the output and avoid overwriting the original file if it fails
    local tmp_file="$(mktemp)"

    
    # use -v to pass the field number to awk because awk does not use bash variables
    # use -F to set the field separator to comma

    awk -v field="$field_number" -F ',' ' 
    { 
        # set output field separator to comma 
        OFS = "," 
        
        # if the field number is greater than the number of fields, print an error message
        if (field > NF) {
            print "Error: Field number exceeds the number of fields in the file." > "/dev/stderr" # use awk syntax to print to stderr
            exit 1
        }
        else if (field < 1 ) {
            print "Error: Field number must be greater than 0." > "/dev/stderr" # use awk syntax to print to stderr
            exit 1
        }

        # set gender to the current value of the field
        gender = $field

        if (gender == "1" || gender == "female")
            $field = "f"
        else if (gender == "0" || gender == "male")
            $field = "m"
        else if (gender == "f" || gender == "m")
            $field = gender
        else
            $field = "u"

        print
    }' "$input_file" > "$tmp_file"

    if [ $? -eq 0 ]; then
        # replace the original file with the temp file that has the changes
        mv "$tmp_file" "$input_file"
        echo "Successfully converted gender field in $input_file."
    else
        echo "Error: Failed to convert $input_file." >&2
        rm "$tmp_file"
        exit 1
    fi
}

function filter_transaction_file() {
    local input_file=$1
    local filter_field=$2 
    local exceptions_file="exceptions.csv"

    # create a temp file to store the output and avoid overwriting the original file if it fails
    local tmp_file="$(mktemp)"

    # use -v to pass the field number and exceptions_file to awk because awk does not use bash variables
    # use -F to set the field separator to comma
    awk -v state_field="$filter_field" -v exceptions="$exceptions_file" -F ',' '

    {
        # set output field separator to comma
        OFS = ","

          # if the field number is greater than the number of fields, print an error message
        if (state_field > NF) {
            print "Error: Field number exceeds the number of fields in the file." > "/dev/stderr" # use awk syntax to print to stderr
            exit 1
        }
        else if (state_field < 1 ) {
            print "Error: Field number must be greater than 0." > "/dev/stderr" # use awk syntax to print to stderr
            exit 1
        }

        # set state to the current value of the field
        state = $state_field

        if (! state || state == "NA") {
            # print these lines to the exceptions file
            print > exceptions
            # skip to the next line to avoid keeping them in correct output
            next
        }

        print 
    }' "$input_file" > "$tmp_file"

    if [ $? -eq 0 ]; then
        # replace the original file with the temp file that has the changes
        mv "$tmp_file" "$input_file"
        echo "Successfully filtered $input_file."
    else
        echo "Error: Failed to filter $input_file." >&2
        rm "$tmp_file"
        exit 1
    fi
}

function remove_dollar_sign() {
    local input_file=$1
    local field_number=$2

    # create a temp file to store the output and avoid overwriting the original file if it fails
    local tmp_file="$(mktemp)"

    # use -v to pass the field number to awk because awk does not use bash variables
    # use -F to set the field separator to comma
    awk -v field="$field_number" -F ',' '
    {
        # set output field separator to comma
        OFS = ","

        # if the field number is greater than the number of fields, print an error message
        if (field > NF) {
            print "Error: Field number exceeds the number of fields in the file." > "/dev/stderr" # use awk syntax to print to stderr
            exit 1
        }
        else if (field < 1 ) {
            print "Error: Field number must be greater than 0." > "/dev/stderr" # use awk syntax to print to stderr
            exit 1
        }

        # set the field to the current value of the field
        purchase_amount = $field

        # remove the dollar sign from the purchase amount using substr
        # if the purchase amount starts with a dollar sign then remove by taking the substring starting from the second character
        if (purchase_amount ~ /^\$/) {
           $field = substr(purchase_amount, 2)
        }

        print 
    }' "$input_file" > "$tmp_file"

    if [ $? -eq 0 ]; then
        # replace the original file with the temp file that has the changes
        mv "$tmp_file" "$input_file"
        echo "Successfully removed dollar sign from $input_file."
    else
        echo "Error: Failed to remove dollar sign from $input_file." >&2
        rm "$tmp_file"
        exit 1
    fi
}

function get_os() {
    local os=$(uname)
    echo "$os"
}