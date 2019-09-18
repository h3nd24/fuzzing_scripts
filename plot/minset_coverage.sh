#!/bin/bash

# TAGS: minset_setup
# Helper script to setup the files for the input of MINSET (Rebert et. al.'s)program.
# PROG is the target, e.g., pdf.
# DIR is the input bitvectors directory.
# OUTDIR is the resulting coverage for the input of MINSET

PROG=${1}
DIR=${2}
OUTDIR=${3}
if [ ! -d ${OUTDIR} ]; then mkdir ${OUTDIR}; fi
if [ ! -d output ]; then mkdir output; fi

for f in $(ls -1 ${DIR}); do
  if [[ ! ${f} == exemplar* ]]; then continue; fi
  FN=${f#exemplar_}
  FN=${FN%\.bv}
  TIME_WEIGHT=$(grep "${f}" ${PROG}_time_weight | awk '{print $2}')
  if [ ! -d ${OUTDIR}/${FN} ]; then mkdir ${OUTDIR}/${FN}; fi
  echo "${PROG},${f}" > output/imagefilemap.txt
  echo "0_0_0_0_0_0_0" > output/info.txt
  echo "0_0_0_0_0_${TIME_WEIGHT}_0" >> output/info.txt
  rm -f output/*.bv
  cp ${DIR}/${f} output/
  ls -l ${DIR}/${f} | awk '{print $5}' > ${OUTDIR}/${FN}/size
  tar -czf output.tgz output
  mv output.tgz ${OUTDIR}/${FN}
done
