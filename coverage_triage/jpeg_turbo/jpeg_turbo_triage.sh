#!/bin/bash

# TAGS: libjpeg-turbo
# Helper script to triage libjpeg-turbo (checking whether a particular seed hits the interesting location).

DEFAULT_ENV_DIR=~/llvm_asan
ENV_DIR=${ENV_DIR:-"${DEFAULT_ENV_DIR}"}

if [ ! -d ${ENV_DIR} ]; then echo "${ENV_DIR} does not exist. Please set the ENV_DIR environment variable"; exit 1; fi

T=${1}    # Distillation techniques
LOW=${2}  # Minimum trial
HIGH=${3} # Maximum trial
NUM_FUZZERS=${NUM_FUZZERS:-2}
source ${ENV_DIR}/jpeg_turbo_env

echo "experiment_type,trial_number,fuzzer_id,queue_id,location_hit"
for t in ${T}; do
  for i in $(seq ${LOW} ${HIGH}); do
    for f in $(seq 1 ${NUM_FUZZERS}); do
      queue_count=$(ls -1 ${t}_${i}/fuzzer0${f}/queue | grep -v README | wc -l)
      printf -v fuzzer_id "fuzzer%02d" ${f}
      if [ "${queue_count}" -eq "0" ]; then continue; fi 
      for c in $(seq 0 $((queue_count-1)) ); do
        echo -n "${t},${i},${f},${c},"
	printf -v queue_id "id:%06d" ${c}
        # seeds in the queue should not crash nor timeout
	${COV_BIN} ${t}_${i}/${fuzzer_id}/queue/${queue_id}* &> exec_log
	if [ ! -f default.profraw ]; then "default.profraw is not produced by ${COV_BIN}, maybe something is wrong with the binary"; fi
	./get_source_profile.sh ${PROG} default
	HIT_COUNT=$(./get_hit_count.sh ${PROG}_coverage jdmarker.c 659)
	if [ "${HIT_COUNT}" -gt "0" ]; then echo "A"; 
	else echo ""; fi
      done
    done
  done
done
