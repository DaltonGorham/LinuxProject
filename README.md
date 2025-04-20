# Linux Project: ETL

## How to run this program
``` bash
./etl.sh <remote_server> <remote_userid> <remote_file>

The command I ran: ./etl.sh "20.102.105.101" "dgorham" "/home/shared/MOCK_MIX_v2.1.csv.bz2"
```


# Languages Used:
* `Bash`
* `Awk`
* `Sed`

# Project WorkFlow

#### The `etl.sh` is the driver for this project, but it relies on the `util_functions.sh` for the logic behind it. 

## 1. Extract the data from server
The `transfer_source_file` function in `util_functions.sh` transfers the `.bz2` source file from a remote server to the local machine using scp and then unzips the source file

## 2. Converting and formatting source file
- To begin the source file is stripped of it's header and translates all letters to lowercase. 
- Then using the `convert_gender_field` function to use *m* and *f* or *u* for the `gender` field. 
- Then it filters out all records where the `state` field is empty or has a value of *"NA"* creating a new *cleaned* source file and also creating a `exceptions.csv` that contains all the records with an empty `state` field. 
- Then it removes the *$* from the `purchase amt` field
- Then sorts the file by `customerID` and creates a final `transaction.csv` file that has all these conversions and filters.

## 3. Create a summary file
- Generates a summary file using the `transaction.csv` file. Accumulates the total purchase amount for each `customerID` and produce a new file with a single record per `customerID `and the total amount overall records for that customer. 
- creates the `summary.csv` file with fields: 

1. customerID 

2. state 

3. zip 

4. lastname 

5. firstname 

6. total purchase amount  

Priority Sorting by:

1. state 

2. zip (descending order) 

3. lastname 

4.  firstname 

## 4. Generate the following two reports using the transaction.csv file.

### Transaction Report - 

* Show the number of transactions by state abbreviation

Example Transaction Report: 
```bash
 head -n 7 transaction-rpt
Report by: [Your Name]
Transaction Count Report

State  Transaction Count
TX     131
CA     103
FL     96
NY     60
```

### Purchase Report - 

* Show the total purchases by gender and state. 

Example Purchase Report:
```bash
$ head -n 7 purchase-rpt
Report by: [Your Name]
Purchase Summary Report

State  Gender Report
TX     F      33734.33
CA     F      23911.61
TX     M      23043.64
FL     M      18846.49
```

