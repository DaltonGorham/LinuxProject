#!/bin/bash
source util_functions.sh


# The script takes three arguments:
# 1. The remote server address
# 2. The remote user ID
# 3. The remote file path

remote_server=$1
remote_userid=$2
remote_file=$3

# grab the users operating system for sed command
os=$(get_os)

# Check if the correct number of arguments is provided
check_arguments "$#"

# Transfer the source file from the remote server to the local machine
transfer_source_file "$remote_server" "$remote_userid" "$remote_file"

# set the transaction_file variable to the name of the file
transaction_file=$(basename "$remote_file")

# unzip the file
echo "Unzipping ${transaction_file}..."
bunzip2 -q "${transaction_file}"
check_exit_status "Failed to unzip ${transaction_file}."
echo "Unzipped ${transaction_file} successfully."

# remove the .bz2 extension from the file name
transaction_file="${transaction_file%.bz2}"

echo "Removing header from ${transaction_file}..."

# remove the header from the transaction_file
sed '1d' "$transaction_file" > cleaned_"$transaction_file"
check_exit_status "Failed to remove header from ${transaction_file}."
echo "Header removed from ${transaction_file} successfully."