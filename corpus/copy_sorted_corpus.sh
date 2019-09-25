#!/bin/bash

# Script to create a (reverse) sorted corpus based on the coverage.
# This fits into AFL behavior which reads the input file in alphabetical order.
INPUT_DIR=${1}   # Source Directory
OUTPUT_DIR=${2}  # Target Directory
SORTED_FILE=${3} # The result of calling sort_coverage.sh
if [ ! -d ${OUTPUT_DIR} ]; then mkdir ${OUTPUT_DIR}; fi
awk -v indir="${INPUT_DIR}" -v outdir="${OUTPUT_DIR}" '{system("cp -v "indir"/"$2" "outdir"/"$3)}' ${SORTED_FILE}
