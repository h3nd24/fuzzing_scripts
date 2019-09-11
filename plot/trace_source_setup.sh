#!/bin/bash
#set -x
PROG=${1}        # e.g., "pdf"
ALG=${2}         # e.g., "cmin"
BUG_ID=${3}      # e.g., "A"
TRIAGE_FILE=${4} # e.g., pdf_triage_result. It is expected to have all of the triage result in this file

# get the maximum of an experiment
MAXTRIAL=$(ls -d fuzz_data/${PROG}_18h/${ALG}_* | grep "${ALG}_[0-9]" | \
      awk 'BEGIN{maxval=0} {n=split($1, a, "_"); if (a[n] > maxval) maxval=a[n]} END{print maxval}') 
echo ${MAXTRIAL}
for i in $(seq 1 ${MAXTRIAL}); do # for all trial of the same distillation, e.g. moonlight_1 .. moonlight_30
  for fuzz_id in {1..8}; do # for all fuzzer
    # create the directory if not exists
    TARGET_DIR=fuzz_data/${PROG}_18h/${ALG}_${i}/fuzzer0${fuzz_id}/crashes_to_trace
    SOURCE_DIR=fuzz_data/${PROG}_18h/${ALG}_${i}/fuzzer0${fuzz_id}/crashes
    if [ ! -d ${TARGET_DIR} ]; then mkdir ${TARGET_DIR}; fi
    rm -f ${TARGET_DIR}/* # clean up the directory
    # for all crashes with a specific bug id, copy to the target directory
    for id in $(grep "${ALG},${i},${fuzz_id}" ${TRIAGE_FILE} | grep "${BUG_ID}" | cut -d, -f4); do
      printf -v FILE "id:%06d*" ${id}
      ln ${SOURCE_DIR}/${FILE} ${TARGET_DIR}/
    done
  done
done
