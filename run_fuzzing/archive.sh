#!/bin/bash

# Script to automatically "clean the queue" (clean_queue.sh) and archive.
# Since we are not using the queue and hangs anymore, we remove the subdirectories from the fuzzing experiment.
set -x
set -e 
PROG=${1} # The prefix of the archive, I used it to indicate the target, e.g., pdf
T=${2}    # The distillation techniques that you want to archive, space separated, e.g., "cmin minset"
LOW=${3}  # The lower number of experiment trial (mainly used if you don't want to start from 1)
HIGH=${4} # The maximum number of experiment trial, usually 30 trials
for i in $(seq ${LOW} ${HIGH}); do 
  for t in ${T}; do 
    echo "${t}_${i}"
    printf -v EXP_NUM "%02d" ${i}
    if [ -f ${PROG}_${t}_llvm_asan_${EXP_NUM}.tar.gz ]; then echo "  archive exists"; continue; fi
    if [ -d ${t}_${i} ]; then 
      if [ ! -d ${t}_${i}/fuzzer01/queue ]; then echo "  queue subdir does not exists"; continue; fi
      ./clean_queue.sh ${t} ${i}
      tar -czf ${PROG}_${t}_llvm_asan_${EXP_NUM}.tar.gz ${t}_${i};
      rm -rf ${t}_${i}/*/hangs; rm -rf ${t}_${i}/*/queue
    fi
  done 
done
