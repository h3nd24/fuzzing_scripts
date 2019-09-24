#!/bin/bash

# TAGS: libxml
# Helper script to triage libxml.
# Since there are fixed for the bugs already, we use the binary to check if a particular fix actually fixed the bug.
# There are a legacy ordering on how the triage was done.

T=${1}    # Distillation techniques
LOW=${2}  # Minimum trial
HIGH=${3} # Maximum trial
rm -f core
echo "experiment_type,trial_number,fuzzer_id,crash_id,bug_id"
for t in ${T}; do
  for i in $(seq ${LOW} ${HIGH}); do
    for f in {1..8}; do
      crash_count=$(ls -1 ${t}_${i}/fuzzer0${f}/crashes | grep -v README | wc -l)
      if [ "${crash_count}" -eq "0" ]; then continue; fi 
      for c in $(seq 0 $((crash_count-1)) ); do
        echo -n "${t},${i},${f},${c},"
        # give 30s timeout after the memory limit increased, to deal with bug C
	rm -f core; timeout 30s ./get_core.sh xml290 ${t}_${i} ${f} ${c} &> /dev/null
	EXIT_STATUS=$?
	# non-bug: previously ASAN OOM, after we add more memory it should dissapear 
	if [ -f core ]; then
          # First try A1, then (A2, J and XA)
          # and then B, and lastly try H-C and X
          # This ordering is legacy, just trying to make it consistent with the other libxml triaging.
          # *) A note about A1 and A2, A2 is the bug A as per the paper (CVE-20158317),
          #   while bug A1 is the actual bug that encompasses both bug A2 and J, which is fixed in 
          #   commit f9e7997e803457b714352c4d51a96104ae298d94 of the repository. 
          #   Unfortunately there is no CVE for this bug and we have to split the CVEs further.
          rm -f core; timeout 30s ./get_core.sh xml290_bugA1 ${t}_${i} ${f} ${c} &> /dev/null
          if [ -f core ]; then # still failing, so fall through to B, and then H-C and X
            PRINT_X=true
            for bug_id in B {H..C}; do 
              rm -f core ; ./get_core.sh xml290_bug${bug_id} ${t}_${i} ${f} ${c} &> /dev/null
              if [ ! -f core ]; then    
                echo -n "${bug_id}"
                PRINT_X=false
                break
              fi
            done
            # the bug is not yet identified
            if [ "${PRINT_X}" = true ]; then echo -n "X"; fi
          else # A1 treats the problem, in that case we need to check for A2 and J
            rm -f core; timeout 30s ./get_core.sh xml290_bugA2 ${t}_${i} ${f} ${c} &> /dev/null
            if [ ! -f core ]; then echo -n "A";
            else
              rm -f core; timeout 30s ./get_core.sh xml290_bugJ ${t}_${i} ${f} ${c} &> /dev/null
              if [ ! -f core ]; then echo -n "J";
              else echo -n "XA"; fi
            fi
          fi
	# bug C: CVE-2015-5312, infinite recursion when it times out
        elif [[ ${EXIT_STATUS} -eq 124 ]]; then 
          rm -f core; timeout 30s ./get_core.sh xml290_bugC ${t}_${i} ${f} ${c} &> /dev/null
	  EXIT_STATUS=$?
	  # if it is still failing with binary for debugging bug C, there might be another issue
	  if [ ! -f core ]; then 
            if [[ ${EXIT_STATUS} -eq 124 ]]; then echo -n "CT"; # if it is not crashing but is timeout
            else echo -n "C"; fi
	  else 
	    echo -n "CX"; 
          fi
	fi	
	echo ""
      done
    done
  done
done
