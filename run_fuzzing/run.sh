#!/bin/bash

# Script to automatically run the fuzzing experiments in the background.
# It will keep spawning fuzzing experiments until the cap on the number of processes is hit.
# This spawning of fuzzing experiments will happen in batch, i.e., currently it is hard-coded to 8 fuzzer instances per experiment trial.
# The script will also keep on spaning fuzzing experiments until the cap on the number of trials is hit.
set -x
RANK=${1}          # an attempt to stack several run.sh together sequentially, e.g., it will block until the lower rank are finished.
T=${2}             # The distillation techniques, space separated, e.g., "cmin minset".
PROG_NAME=${3}     # Target program
EXPERIMENT_ID=${4} # The starting number for the experiments. It will be incremented while the cap on number of processes is not hit.
PROCESS_CAP=72
EXPERIMENT_CAP=30

# Block until the run.sh with lower ranks are finished
while [ "$(ps -ef | grep 'run.sh' | grep "${USER}" | grep -v 'grep' | awk '{if ($3 != 1) print $10}' |\
	sort -nr | tail -n 1)" -lt "${RANK}" ]; do echo "waiting for lower rank"; sleep 300; done

# Keep spawning fuzzing experiments until the cap on the number of trial is hit
while true; do
  # Iterate over the distillation techniques
  for t in ${T}; do
    # Block while the cap on number of processes is hit
    while [ "$(ps -ef | grep "hendrag" | grep "timeout 18h" | grep "${PROG_NAME}" | grep -v grep | wc -l)" -ge "${PROCESS_CAP}" ]; do 
      echo "waiting to execute ${t}_${EXPERIMENT_ID}"; sleep 300; 
    done
    # Skip pre-existing fuzzing experiments
    if [ ! -d ${t}_${EXPERIMENT_ID} ]; then
      # Spawn 8 instances of fuzzers 
      for i in $(seq 1 8); do ./fuzz.sh ${PROG_NAME} ${t} ${EXPERIMENT_ID} ${i} & sleep 1; done
    fi
    sleep 5
  done
  EXPERIMENT_ID=$((EXPERIMENT_ID + 1))
  if [ "${EXPERIMENT_ID}" -gt "${EXPERIMENT_CAP}" ]; then break; fi
done
