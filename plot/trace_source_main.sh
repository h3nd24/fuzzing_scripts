#!/bin/bash

# TAGS: trace_source
# (Deprecated) Script to setup the tracing crashes back to its source 
#set -x
PROG=${1}                 # e.g., "sox"
ALGS=${2}                 # e.g., "full cmin minset moonshine_size empty random"
BUGS=${3}                 # e.g., "A B C D E F G H"
COMBINED_TRIAGE_FILE=${4} # e.g., sox_triage_result. It is expected to have all of the triage result in this file

for alg in ${ALGS}; do
  for bug_id in ${BUGS}; do
    ./trace_source_setup.sh ${PROG} ${alg} ${bug_id} ${COMBINED_TRIAGE_FILE} 
    for i in {1..30}; do
      python trace_source.py -o trace_source/${PROG}_${bug_id}_${alg}_${i} fuzz_data/${PROG}_18h/${alg}_${i}
    done
  done
done
