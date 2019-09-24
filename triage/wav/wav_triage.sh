#!/bin/bash

# TAGS: SoX (WAV)
# Helper script to triage bugs on SoX (WAV).
# This script is mostly similar to SoX (MP3), except that there are 2 bugs missing and 1 additional bug. 

T=${1}    # Distillation Techniques
LOW=${2}  # Minimum trial
HIGH=${3} # Maximum trial
echo "experiment_type,trial_number,fuzzer_id,crash_id,bug_id"
for t in ${T}; do
  for i in $(seq ${LOW} ${HIGH}); do
    for f in {1..8}; do
      crash_count=$(ls -1 ${t}_${i}/fuzzer0${f}/crashes | grep -v README | wc -l)
      if [ "${crash_count}" -eq "0" ]; then continue; fi 
      for c in $(seq 0 $((crash_count-1)) ); do
        echo -n "${t},${i},${f},${c},"
        ./get_core.sh sox ${t}_${i} ${f} ${c} &> crash_log
	# Bug A: remix.c:237 || remix.c:238
	if [ ! -z "$(grep -e "remix.c:237" -e "remix.c:238" crash_log)" ]; then 
          if [ ! -z "$(grep "heap-buffer-overflow" crash_log)" ]; then echo -n "A"; 
          else echo -n "X"; fi
	# Bug B & C: effects_i_dsp.c
	elif [ ! -z "$(grep "#0" crash_log | grep "effects_i_dsp.c")" ]; then 
          if [ ! -z "$(grep "SEGV" crash_log)" ]; then echo -n "B"; 
	  elif [ ! -z "$(grep "heap-buffer-overflow" crash_log)" ]; then echo -n "C"; 
          else echo -n "X"; fi
	# Bug D: fft4g.c
	elif [ ! -z "$(grep "fft4g.c:721" crash_log)" ]; then
          if [ ! -z "$(grep "stack-buffer-overflow" crash_log)" ]; then echo -n "D"; 
          else echo -n "X"; fi
	# Bug E: FPE on wav.c:950
	elif [ ! -z "$(grep FPE crash_log)" ]; then
          if [ ! -z "$(grep" wav.c:950" crash_log)" ]; then echo -n "E"; 
          else echo -n "X"; fi
	# Bug F: formats_i.c:98
	elif [ ! -z "$(grep" formats_i.c:98" crash_log)" ]; then
	  if [ ! -z "$(grep SEGV crash_log)" ]; then echo -n "F"; 
          else echo -n "X"; fi
	# failed assertions 
	elif [ ! -z "$(grep "Assertion" crash_log)" ]; then 
          if [ ! -z "$(grep -e "lsx_is_power_of_2(len)" -e "rate.c:303: void rate_init" crash_log)" ]; then echo -n ""; 
          else echo -n"X"; fi
        else echo -n "X";
	fi	
	echo ""
      done
    done
  done
done
