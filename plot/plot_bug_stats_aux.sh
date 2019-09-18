#!/bin/bash

# TAGS: speedup_plot
# Wrapper script to call plot_bug_stats.R
PROG=${1}
OUTPUT=${2}
BUGS=""
ALGS=""
ALL_ALGS="cmin moonshine_size minset empty" 

for a in ${ALL_ALGS}; do
  if [ ! -z "$(ls ${PROG}_18h_bug_stats_${a}_1 2> /dev/null)" ]; then ALGS=${ALGS}"$a "; fi
done
for b in {A..Z}; do 
  FOUND=false
  for a in ${ALGS}; do
    if [ ! -z "$(cat ${PROG}_18h_bug_stats_${a}_[0-9]* | grep "$b")" ]; then 
      BUGS=${BUGS}"$b "; 
      FOUND=true;
      break;
    fi
  done
done

if   [ "${PROG}" == "pdf"         ]; then EXPANDED_PROG="Poppler";
elif [ "${PROG}" == "sox"         ]; then EXPANDED_PROG="SoX (MP3)";
elif [ "${PROG}" == "wav"         ]; then EXPANDED_PROG="SoX (WAV)";
elif [ "${PROG}" == "svg24020"    ]; then EXPANDED_PROG="librsvg";
elif [ "${PROG}" == "ttf253"      ]; then EXPANDED_PROG="FreeType";
elif [ "${PROG}" == "xml290"      ]; then EXPANDED_PROG="libxml";
elif [ "${PROG}" == "tiff409c710" ]; then EXPANDED_PROG="libtiff"
fi;

Rscript plot_bug_stats.R --output ${OUTPUT} --bugs "${BUGS}" --inputprefix "${PROG}_18h_bug_stats" \
  --title "Speedup Plot - ${EXPANDED_PROG}" --algnames "${ALGS}" # --xmax $(./get_max_execs.sh ${PROG})
