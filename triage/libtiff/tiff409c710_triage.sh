#!/bin/bash

# TAGS: libtiff
# Helper script to triage libtiff. 
# Bugs A-C are debugged using gdb, we know that the particular bug is triggered when gdb hits a breakpoint.
# We can tell that it is bug D from the infinite loop.

T=${1}    # Distillation techniques, comma separated, e.g., "cmin minset"
LOW=${2}  # The lower number of the experiments that we want to triage
HIGH=${3} # The maximum number of the experiments that we want to triage
rm -f core
echo "experiment_type,trial_number,fuzzer_id,crash_id,bug_id"
for t in ${T}; do
  for i in $(seq ${LOW} ${HIGH}); do
    for f in {1..8}; do
      crash_count=$(ls -1 ${t}_${i}/fuzzer0${f}/crashes | grep -v README | wc -l)
      if [ "${crash_count}" -eq "0" ]; then continue; fi 
      for c in $(seq 0 $((crash_count-1)) ); do
        echo -n "${t},${i},${f},${c},"
        rm -f core
        timeout 30s ./get_core.sh tiff409c710 ${t}_${i} ${f} ${c} &> /dev/null
        EXIT_STATUS=$?
        # case 1: check timeout for bug D
        if [ -f core ]; then
          # case 2 : bug A, Integer Overflow on malloc check
          rm -f core
          PRINT_X=true
          for bug in {A..C}; do
            ./debug_tiff_aux.sh tiff409c710 ${bug} ${t}_${i} ${f} ${c} &> debug_log_2
	          if [ -z "$(grep "ERROR: AddressSanitizer" debug_log_2)" ]; then 
              echo -n "${bug}";
              PRINT_X=false
              break;
            fi
            # the bug is not yet identified
          done
          if [ "${PRINT_X}" = true ]; then echo -n "X"; fi
        elif [[ ${EXIT_STATUS} -eq 124 ]]; then 
      	  echo -n "D"; 
      	fi	
	      echo ""
      done
    done
  done
done
