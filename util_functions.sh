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


function generate_summary_file() {
    local input_file=$1

    # since the file is already sorted by customer ID, we can use awk to accumulate the purchase amounts if the customer ID is the same as the last one

    awk -F ',' '
    BEGIN {
        OFS = ","
        last_customerID = ""
        total_purchase_amount = 0
        total_records = 0
    }
    {
        customerID = $1
        first_name = $2
        last_name = $3
        purchase_amount = $6
        state = $12
        zip = $13

        # start with the first record
        if (last_customerID == ""){
            last_customerID = customerID
            last_state = state
            last_zip = zip
            last_name_saved = last_name
            first_name_saved = first_name
            total_purchase_amount = purchase_amount
            total_records = 1
        }
        else if (customerID == last_customerID) {
            # if the customer ID is the same as the last one, add to the total purchase amount
            total_purchase_amount += purchase_amount
            total_records++
        }
        else {
            # if the customer ID is different, print the summary for the last customer
            print last_customerID, last_state, last_zip, last_name_saved, first_name_saved, total_purchase_amount, total_records

            # reset for the new customer
            last_customerID = customerID
            last_state = state
            last_zip = zip
            first_name_saved = first_name
            last_name_saved = last_name
            total_purchase_amount = purchase_amount
            total_records = 1
        }
    }
    END {
        # print the summary for the last customer because it wont be printed in the main block
        print last_customerID, last_state, last_zip, last_name_saved, first_name_saved, total_purchase_amount, total_records
    }' "$input_file" > "temp_summary_file.csv"

    check_exit_status "Failed to generate summary file from $input_file."


    # sort the summary file 
    echo "Sorting summary file..."
    sort_summary_file "temp_summary_file.csv"
    check_exit_status "Failed to sort summary file from $input_file."

    echo "Successfully generated summary file from $input_file."
    rm "temp_summary_file.csv"
}

function generate_transaction_report() {
    local input_file=$1

    # use cut to extract the state field and sort it to get a summary of the number of transactions per state
    # use tr to convert all text to uppercase
    # use sort to sort the output for uniq
    # use uniq -c to count the number of occurrences of each state
    # use sort -nr to sort the output by the number of occurrences
    # pipe to awk to format the output
    cut -d ',' -f12 "$input_file" | tr '[:lower:]' '[:upper:]' | sort | uniq -c |  sort -nr | awk '
        BEGIN {
            OFS = ","
            print "Report by: Dalton Gorham"
            print "Transaction Count Report"
            print ""
            printf "%-10s %-10s\n", "State", "Transaction Count"
        }
        {
            # print the state and the count
            printf "%-10s %-10s\n", $2, $1
        }' > "transaction.rpt"
    check_exit_status "Failed to generate transaction report from $input_file."
    echo "Successfully generated transaction report from $input_file."
}

function generate_purchase_report() {
    local input_file=$1

    # use awk here ecause cut does not support grouping by multiple fields
    
    awk -F ',' '
    BEGIN {
        OFS = ","
    }
    {
        # use toupper function to convert into uppercase
        state = toupper($12)
        gender = toupper($5)
        purchase_amount = $6 + 0 # convert to number to avoid using as string
       
       # to associate the state and gender with the purchase amount, we need to create a key 
       # then we can use the key to group the purchase amounts
       # this is mimicking a hash table
       key = state "-" gender
       total[key] += purchase_amount


    }
    END {
        # now we can break the key into its components and print the results
        for (key in total) {
            split(key, parts, "-")
            printf "%s,%s,%.2f\n", parts[1], parts[2], total[key]
        }
        }' "$input_file" > "purchase_tmp.rpt" 

        sort -t ',' -k 3,3nr -k1,1 -k2,2 "purchase_tmp.rpt" > "purchase_tmp_sorted.rpt"

    check_exit_status "Failed to generate tmp purchase report from $input_file."

    # use awk again to actually format the output
    awk -F ',' '
    BEGIN {
        OFS = ","
        print "Report by: Dalton Gorham"
        print "Purchase Summary Report"
        print ""
        printf "%-10s %-10s %-10s\n", "State", "Gender", "Report"
        }

        # print the report body
        {
            printf "%-10s %-10s %-10.2f\n", $1, $2, $3 
        }' "purchase_tmp_sorted.rpt" > "purchase.rpt"

    check_exit_status "Failed to generate purchase report from $input_file."
    echo "Successfully generated purchase report from $input_file."
    rm "purchase_tmp.rpt"
    rm "purchase_tmp_sorted.rpt"

}


function sort_summary_file() {
    local input_file=$1

   # Sort the summary file based upon
   # 1. state
   # 2. zip (descending)
   # 3. last name
   # 4. first name
    sort -t ',' -k 2,2 -k 3,3nr -k 4,4 -k 5,5 "$input_file" > "summary.csv"
    check_exit_status "Failed to sort summary file $input_file."
}
    