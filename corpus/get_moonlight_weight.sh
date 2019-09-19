#!/bin/bash

# Takes the output of combine_time_size.sh and extract the weight of a corpus for further processing by MoonLight.

PROG=${1}
T=${2}
if [ ! -f ${PROG}_${T}_time_size ]; then echo "${PROG}_${T}_time_size does not exists"; exit 1; fi
#awk '{split($2,a,"/"); print "exemplar_"a[2]".bv "$4}' ${PROG}_time > ${PROG}_time_weight
sed "1d" ${PROG}_${T}_time_size | awk -F "," '{print "exemplar_"$1".bv "$2}' > ${PROG}_size_weight
sed "1d" ${PROG}_${T}_time_size | awk -F "," '{printf "%s %.0f\n" ,"exemplar_"$3".bv",$4}' > ${PROG}_time_weight
