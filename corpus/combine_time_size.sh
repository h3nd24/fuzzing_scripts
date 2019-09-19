#!/bin/bash

# Simple script to combine the time weight and the size weight into one file.
# Takes the output of get_size.sh and check_timeout.sh
set -x
DIR=${1}
paste -d"," ${DIR}_size <(awk '{split($2, a, "/"); print a[2]","$4}' ${DIR}_time) > ${DIR}_time_size
