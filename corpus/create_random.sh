#!/bin/bash

# Script to create 30 randomly generated corpus (taken from the initial full corpus).
# The number 30 here corresponds to the number of trial we used in the paper.

PROG=${1}   # Target
SOURCE=${2} # The source directory, ideally this is the full corpus
Nseed=${3}  # The number of seed to randomly select from the full corpus. 
            # For MoonLight paper, this number is equal to the number of seed in Unweighted MoonLight case.
for i in {1..30}; do
  echo "${PROG} ${i}"
  if [ ! -d ${PROG}_random_${i}_llvm_asan ]; then
    mkdir ${PROG}_random_${i}_llvm_asan
    for f in $(shuf -n ${Nseed} <(ls -1 ${SOURCE}) ); do
      ln ${SOURCE}/${f} ${PROG}_random_${i}_llvm_asan/${f}
    done
  fi
done
