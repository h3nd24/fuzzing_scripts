#!/bin/bash

# Simple script to check the number of fuzzers that are alive at some point (as indicated by the existence of "fuzzer_stats".

T=${1}
LOW=${2}
HIGH=${3}

for t in ${T}; do
  for i in $(seq ${LOW} ${HIGH}); do
    if [ ! -d "${t}_${i}" ]; then 
      echo "${t}_${i} does not exist"
      continue; 
    fi
    count=$(ls ${t}_${i}/fuzzer*/fuzzer_stats | wc -l)
    echo "${t}_${i} : ${count}"
  done
done
