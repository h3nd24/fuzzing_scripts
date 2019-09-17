#!/bin/bash

# this script takes the triage result (CSV file) as an input and output the count of distinct bugs

FILE=${1}

cut -d, -f2,5 ${FILE} | sort | uniq -c | cut -d, -f2 | sort | uniq -c
