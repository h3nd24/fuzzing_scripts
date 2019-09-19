#!/bin/bash

# Sort the coverage based on the number of AFL unique edges in the directory.
# This works because we just have AFL tuples in the directory, and each unique edge in the file occupies one line.

# assume only the tuples files are in the DIR
DIR=${1}

wc -l ${DIR}/* | sort -nk1 | awk 'BEGIN{count=0} {if ($2 != "total") 
  {split ($2, a, "."); split ($2, b, "-"); printf "%d %s %03d.%s\n", $1, b[2], count, a[2]; count += 1}}';

