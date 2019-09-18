#!/bin/bash

# TAGS: bugs_over_time
# take the filename of the actual crashes and a bug report,
# this script will fill in the rest of the crashes with no bug ID ("")

BASE_DIR=$1
BUG_FILE=$2
OUT_FILE=$3

echo "experiment_type,trial_number,fuzzer_id,crash_id,bug_id" > ${OUT_FILE}

for exp in $(ls -1 ${BASE_DIR}); do 
  if [ "${exp}" == "stack_hashes" ]; then continue; fi
  EXP_TYPE=${exp%_*}
  TRIAL_NUMBER=${exp##*_}
  echo "${exp} - ${EXP_TYPE} ${TRIAL_NUMBER}"
  for fuzzer in $(ls -1 ${BASE_DIR}/${exp}); do
    FUZZ_ID=$(echo ${fuzzer:6} | awk '{printf "%d\n",$0;}')
    for f in $(ls -1 ${BASE_DIR}/${exp}/${fuzzer}/crashes | grep "id:"); do
      CRASH_ID=$(echo ${f%%,*} | sed 's/id://' | awk '{printf "%d\n",$0;}')
      BUG_ID=$(grep "${EXP_TYPE},${TRIAL_NUMBER},${FUZZ_ID},${CRASH_ID}," ${BUG_FILE} | cut -d, -f5)
      if [ -z "${BUG_ID}" ]; then BUG_ID=""; fi
      echo "${EXP_TYPE},${TRIAL_NUMBER},${FUZZ_ID},${CRASH_ID},${BUG_ID}" >> ${OUT_FILE}
    done
  done
done
