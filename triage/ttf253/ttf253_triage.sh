#!/bin/bash

# TAGS: FreeType
# Triage script for FreeType.
# There are fixes already for the bugs so we used the patch to distinguish the bug,
# i.e., if a particular patch (associated with a CVE) fixes the bug, then the crashing seed is classified as that bug.

T=${1}    # Distillation techniques
LOW=${2}  # Minimum trial
HIGH=${3} # Maximum trial
rm -f core
echo "experiment_type,trial_number,fuzzer_id,crash_id,bug_id"
for t in ${T}; do
  for i in $(seq ${LOW} ${HIGH}); do
    for f in {1..8}; do
      crash_count=$(ls -1 ${t}_${i}/fuzzer0${f}/crashes 2> /dev/null | grep -v README | wc -l)
      if [ "${crash_count}" -eq "0" ]; then continue; fi 
      for c in $(seq 0 $((crash_count-1)) ); do
        PRINT_X=true
        for bug_id in {A..H}; do 
          rm -f core ; ./get_core.sh ttf253_bug${bug_id} ${t}_${i} ${f} ${c} &> /dev/null
          if [ ! -f core ]; then    
            echo "${t},${i},${f},${c},${bug_id}"
            PRINT_X=false
            break
          fi
        done
        # the bug is not yet identified
        if [ "${PRINT_X}" = true ]; then echo "${t},${i},${f},${c},X"; fi
      done
    done
  done
done
