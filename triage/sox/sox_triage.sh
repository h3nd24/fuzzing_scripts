#!/bin/bash

# TAGS: SoX (MP3)
# Helper script to triage bugs on SoX (MP3). 
# There are no fixed yet for most of them, fortunately, the stack traces are unique to the bugs.
# So in this case we just do grepping from the ASAN output and its stack trace.

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
	# Bug A: memcpy overlap
	if [ ! -z "$(grep "memcpy-param-overlap" crash_log)" ]; then
          if [ ! -z "$(grep "mp3-util.h:277" crash_log)" ]; then echo -n "A"; 
          else echo -n "X"; fi
	# Bug B: remix.c:237 || remix.c:238
	elif [ ! -z "$(grep -e "remix.c:237" -e "remix.c:238" crash_log)" ]; then 
          if [ ! -z "$(grep "heap-buffer-overflow" crash_log)" ]; then echo -n "B"; 
          else echo -n "X"; fi
	# Bug C: mp3.c:520a
        elif [ ! -z "$(grep -e "mp3.c:520" -e "mp3.c:417" crash_log)" ]; then 
          if [ ! -z "$(grep "mad_" crash_log)" ]; then echo -n "C"; 
          else echo -n "X"; fi
	# Bug D & E: effects_i_dsp.c
	elif [ ! -z "$(grep "#0" crash_log | grep "effects_i_dsp.c")" ]; then 
          if [ ! -z "$(grep "SEGV" crash_log)" ]; then echo -n "D"; 
	  elif [ ! -z "$(grep "heap-buffer-overflow" crash_log)" ]; then echo -n "E"; 
          else echo -n "X"; fi
	# Bug F: fft4g.c
	elif [ ! -z "$(grep "fft4g.c:721" crash_log)" ]; then
          if [ ! -z "$(grep "stack-buffer-overflow" crash_log)" ]; then echo -n "F"; 
          else echo -n "X"; fi
	# Bug G: xa.c:219
	elif [ ! -z "$(grep xa.c:219 crash_log)" ]; then
	  if [ ! -z "$(grep SEGV crash_log)" ]; then echo -n "G"; 
          else echo -n "X"; fi
	# Bug H: formats_i.c:98
	elif [ ! -z "$(grep" formats_i.c:98" crash_log)" ]; then
	  if [ ! -z "$(grep SEGV crash_log)" ]; then echo -n "H"; 
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
