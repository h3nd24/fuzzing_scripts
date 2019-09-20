#!/bin/bash

# Simple helper script to empty the content of the seeds in the fuzzer's queue ,
# i.e., create a new empty file with the same name as the seeds in the queue.

TYPE=${1}    # distillation technique, e.g., cmin
EXP_NUM=${2} # the trial number

for i in {1..8}; do
  for f in $(ls -1 ${TYPE}_${EXP_NUM}/fuzzer0${i}/queue); do
    rm ${TYPE}_${EXP_NUM}/fuzzer0${i}/queue/${f};
    touch ${TYPE}_${EXP_NUM}/fuzzer0${i}/queue/${f}
  done
done
