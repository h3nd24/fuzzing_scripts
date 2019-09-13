#!/bin/bash
set -x
set -e 
PROG=${1} # e.g., pdf
OUT_DIR=dedup_plot_data # where to store intermediary output data for processing which are then used by the plotting script as input
#ALL_ALGS="cmin moonshine moonshine_size moonshine_time empty full"
ALL_ALGS="full cmin minset moonshine_size empty random"
ALGS=
MAX_TRIALS_R=""
CAP_TRIALS=30
TIME_H=${2} # time in hours
TIME_LIMIT=$(echo "${TIME_H} * 3600" | bc)

if [ ! -d ${OUT_DIR} ]; then mkdir ${OUT_DIR}; fi
CONCLUSION="F"
if [[ "$#" -gt 2 ]]; then CONCLUSION="T"; fi 
#PLOT_ONLY=false
#echo ${PLOT_ONLY}

for alg in ${ALL_ALGS}; do
  # check if the experiment for a particular distillation technique  xists
  if [ ! -z $(ls -d fuzz_data/${PROG}_${TIME_H}h/triage_output/${alg}_* 2>&1 | grep "${alg}_[0-9]" | head -n 1) ]; then 
    ALGS=${ALGS}"${alg} "
    MAX_TRIALS=$(ls -d fuzz_data/${PROG}_${TIME_H}h/triage_output/${alg}_* | grep "${alg}_[0-9]" | \
      awk 'BEGIN{maxval=0} {n=split($1, a, "_"); if (a[n] > maxval) maxval=a[n]} END{print maxval}')
    if [ "${MAX_TRIALS}" -gt "${CAP_TRIALS}" ]; then MAX_TRIALS=${CAP_TRIALS} ; fi
    MAX_TRIALS_R=${MAX_TRIALS_R}${MAX_TRIALS}" "
    CHANGED=false
    for i in $(seq 1 ${MAX_TRIALS}); do
      # if there was pre-existing trial data, then skip
      if [ ! -f ${OUT_DIR}/${PROG}_${TIME_H}h_bug_crashes_${alg}_${i} ]; then 
        python time_to_find.py -i fuzz_data/${PROG}_${TIME_H}h --experiment ${alg}_${i} --time-cap ${TIME_LIMIT} \
          -o ${OUT_DIR}/${PROG}_${TIME_H}h_bug_crashes_${alg}_${i} --bug-stats ${OUT_DIR}/${PROG}_${TIME_H}h_bug_stats_${alg}_${i};
        CHANGED=true
      fi
    done
    # only recalculate the aggregate data when there is a change on any of the trial
    if [ "${CHANGED}" = true ]; then 
    	python dedup_average.py -i ${OUT_DIR} -e ${alg} -o ${OUT_DIR}/${PROG}_${TIME_H}h_bug_crashes_${alg}_avg \
        -m ${MAX_TRIALS} --prefix "${PROG}_${TIME_H}h_bug_crashes" ;
#     We don't need the combined bug stats for now since we are working on individual bug stat
#      python combine_bug_stats.py -i dedup_plot_data/${PROG}_${TIME_H}h_bug_stats_${alg} --max-trials ${MAX_TRIALS} \
#        --output-count dedup_plot_data/${PROG}_${TIME_H}h_bug_stats_${alg}_count \
#        --output-avg dedup_plot_data/${PROG}_${TIME_H}h_bug_stats_${alg}_avg \
#        --output-comb dedup_plot_data/${PROG}_${TIME_H}h_bug_stats_${alg}_comb;
      # calculate AUC
      Rscript calculate_AUC.R --algnames "${alg}" --maxtrials "${MAX_TRIALS}" --inputdir "dedup_plot_data" \
        --inputprefix "${PROG}_${TIME_H}h_bug_crashes" --outputprefix "${PROG}_${TIME_H}h_bug_crashes" --outputpostfix "AUC" \
        --fieldname "num_crashes"   
      # get the display data, basically this is reducing the number of visible data points in the plot so that it is much quicker to plot
      Rscript get_display_data.R --algnames "${alg}" --maxtrials "${MAX_TRIALS}" --inputdir "dedup_plot_data" \
        --inputprefix "${PROG}_${TIME_H}h_bug_crashes" --inputpostfix "avg" --fieldname "num_crashes" \
        --outputprefix "${PROG}_${TIME_H}h_bug_crashes" --outputpostfix "display_data"
    fi
  fi
done

# special treatment for legend position that has to change due to various reason, e.g., covering the curves
LEGENDPOS="topleft"
if [ "${PROG}" = "xml290" ]; then LEGENDPOS="bottomright"; fi

# actually plotting the data
Rscript plot.R --algnames "${ALGS}" --maxtrials "${MAX_TRIALS_R}" --inputdir "plot_data_stats" \
  --inputprefix "${PROG}_${TIME_H}h_bug_crashes" --inputpostfix "display_data" --statpostfix "AUC" \
  --output "Crashes-bug-${PROG}-${TIME_H}-avg.pdf" --fieldname "num_crashes" \
  --ylab "Average Bugs Found" --sublab "#Bugs against Iterations" \
  --title "${PROG} - #Bugs found over 18 hours of Fuzzing Experiments" \
  --legendpos "${LEGENDPOS}" --conclusion ${CONCLUSION}
