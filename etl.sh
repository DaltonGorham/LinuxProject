#!/bin/bash
source util_functions.sh # source the utility functions for error checking and other utilities

# Name: Dalton Gorham
# Date: 04/19/2025
# Assignment: Semester Project ETL


# The script takes three arguments:
# 1. The remote server address
# 2. The remote user ID
# 3. The remote file path

remote_server=$1
remote_userid=$2
remote_file=$3

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

echo "Removing header and converting all text to lowercase in ${transaction_file}..."

# remove the header from the transaction_file and convert all text to lowercase
sed '1d' "$transaction_file" | tr '[A-Z]' '[a-z]' > cleaned_"$transaction_file"
check_exit_status "Failed to reformat ${transaction_file}."
echo "Successfully removed header and translated all text to lowercase for ${transaction_file}."
echo "Created new formatted file: cleaned_${transaction_file}"

# use the cleaned file without the header and lowercase letters for the rest of the script
cleaned_transaction_file="cleaned_${transaction_file}"

# convert the "gender" field to use "f" and "m" or "u"
echo "Converting gender field in ${cleaned_transaction_file}..."
convert_gender_field "${cleaned_transaction_file}" 5
check_exit_status "Failed to convert the gender field in ${cleaned_transaction_file}."

# place all records that do not contain a state in exceptions.csv and remove them from the cleaned file
echo "Filtering records that do not contain a state in ${cleaned_transaction_file}..."
echo "Creating exceptions.csv file..."
filter_transaction_file "${cleaned_transaction_file}" 12

echo "Removing the $ sign from the transaction amount field in ${cleaned_transaction_file}..."
remove_dollar_sign "${cleaned_transaction_file}" 6

# sort the cleaned file by customer ID and place it in the final transaction.csv file
echo "Sorting ${cleaned_transaction_file} by customer ID..."
sort -t ',' -n -k 1,1 "${cleaned_transaction_file}" > "transaction.csv"
check_exit_status "Failed to sort ${cleaned_transaction_file}."
echo "Successfully sorted ${cleaned_transaction_file} by customer ID."
echo "Removing ${cleaned_transaction_file} and placing sorted records in transaction.csv..."
rm "${cleaned_transaction_file}"

echo "Generating summary file..."
generate_summary_file "transaction.csv"

echo "Generating Transaction Report..."
generate_transaction_report "transaction.csv"

echo "Generating Purchase Report..."
generate_purchase_report "transaction.csv"




