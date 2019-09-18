#!/bin/bash
set -x
set -e 

# Wrapper script that produces plots for coverage information on the experiments result
PROG=${1}
CAP_TRIALS=30
TIME_H=${2}
TIME_LIMIT=$(echo "${TIME_H} * 3600" | bc)
PLOT_ONLY=false
if [[ "$#" -gt 2 ]]; then PLOT_ONLY=true; fi 
OUT_DIR=raw_plot_data
if [ ! -d ${OUT_DIR} ]; then mkdir ${OUT_DIR}; fi
ALL_ALGS="full cmin minset moonshine_size empty random"
ALGS=

echo "generating plot data and AUC..."
MAX_TRIALS_R=""
for alg in ${ALL_ALGS}; do
  # check if the "minimization algorithm experiment exists"
  if [ ! -z $(ls -d fuzz_data/${PROG}_${TIME_H}h/${alg}_* 2>&1 | grep "${alg}_[0-9]" | head -n 1) ]; then 
    ALGS=${ALGS}"${alg} "
    MAX_TRIALS=$(ls -d fuzz_data/${PROG}_${TIME_H}h/${alg}_* | grep "${alg}_[0-9]" | \
      awk 'BEGIN{maxval=0} {n=split($1, a, "_"); if (a[n] > maxval) maxval=a[n]} END{print maxval}')
    if [ "${MAX_TRIALS}" -gt "${CAP_TRIALS}" ]; then MAX_TRIALS=${CAP_TRIALS} ; fi
    MAX_TRIALS_R=${MAX_TRIALS_R}${MAX_TRIALS}" "
    if [ "$PLOT_ONLY" = false ]; then 
      COMMON_ARGS="-i fuzz_data/${PROG}_${TIME_H}h -o ${OUT_DIR}/${PROG}_${TIME_H}h -m ${MAX_TRIALS} --time-cap ${TIME_LIMIT}"
      python generate_plot_data.py ${COMMON_ARGS} --algs "${alg}" 
    fi
  fi
done
#python generate_plot_data.py ${COMMON_ARGS} ${ALGS} --execs-cap ${EXECS_CAP} 
#echo "combining the stats..."
#./get_stats_overview.sh ${PROG} ${MAX_TRIALS}
if [ "${PLOT_ONLY}" = false ]; then
  Rscript calculate_AUC.R --algnames "${ALGS}" --maxtrials "${MAX_TRIALS_R}" --inputdir "raw_plot_data" \
    --inputprefix "${PROG}_${TIME_H}h_coverage" --outputprefix "${PROG}_${TIME_H}h_coverage" --outputpostfix "AUC" \
    --fieldname "map_size"   
  Rscript get_display_data.R --algnames "${ALGS}" --maxtrials "${MAX_TRIALS_R}" --inputdir "raw_plot_data" \
    --inputprefix "${PROG}_${TIME_H}h_coverage" --inputpostfix "avg" --fieldname "map_size" \
    --outputprefix "${PROG}_${TIME_H}h_coverage" --outputpostfix "display_data"
#  Rscript get_CI.R --target ${PROG} --algnames "${ALGS}" --maxtrials "${MAX_TRIALS_R}" --timelimit ${TIME_H} --inputdir raw_plot_data --inputinfix plot_data --outputinfix raw
fi

echo "generating plots..."
LEGEND_POS_COV="bottomright"
if [ "${PROG}" = "tiff409c7" ]; then LEGEND_POS_COV="bottomright"; LEGEND_POS_CRASHES="topleft"; fi

Rscript plot.R --algnames "${ALGS}" --maxtrials "${MAX_TRIALS_R}" --inputdir "plot_data_stats" \
  --inputprefix "${PROG}_${TIME_H}h_coverage" --inputpostfix "display_data" --statpostfix "AUC" \
  --output "Coverage-${PROG}-${TIME_H}-avg.pdf" --fieldname "map_size" \
  --ylab "Coverage (%)" --sublab "Coverage against Iterations" \
  --title "${PROG} Coverage of 18 hours of Fuzzing Experiments" --legendpos "${LEGEND_POS_COV}" --conclusion=F

