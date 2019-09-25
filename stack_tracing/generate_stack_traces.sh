#!/bin/bash

# Script to iterate over the distillation techniques and all of the fuzzing experiments and call get_stack_traces on each of them.

PROG=${1}     # The target, mainly used to address the program config / environment variables, e.g., pdf
DIR=${2}      # The root directory containing all of the fuzzer campaigns of a target, e.g., pdf. 
              # For convenience, the current directory is the same as the target name. 
              # However, this is left here to provide some flexibility.
ALGNAMES=${3} # Distillation techniques, space separated, e.g., "full cmin minset"
LOW=${4}      # Minimum trial
HIGH=${5}     # Maximum trial

if [ ! -d ${PROG} ]; then mkdir ${PROG}; fi
cd ${DIR}

for alg in ${ALGNAMES}; do
  for i in $(seq ${LOW} ${HIGH}); do
    echo "Processing ${alg} ${i}"
    if [ ! -d ${alg}_${i} ] && [ ! -f ${alg}_${i} ]; then continue; fi # skip if we can't find the fuzzer output directory / soft link
    ../get_stack_traces.sh ~/llvm_asan/${PROG}_env ${alg}_${i}
  done
done
