#!/bin/bash

# Helper script to gather some statistics of the corpora based on the files in the solution and the weight files (time and size).
# This is primarily used to fill the corpus table in the MoonLight paper.

SOLFILE=${1}    # e.g., ~/corpus/llvm_asan/sox_minset_solution.json
TIMEWEIGHT=${2} # e.g., ~/corpus/llvm_asan/sox_time_weight 
SIZEWEIGHT=${3} # e.g., ~/corpus/llvm_asan/sox_size_weight

FS() { ( for f in $(grep ".bv" $1 | cut -d\" -f2); do 
  grep "${f}" ${2} | cut -d\  -f2 ; 
done | paste -sd+ | xargs -I{} echo "scale=4; ({}) / 1048576.0" | bc ) }

FT() { ( for f in $(grep ".bv" $1 | cut -d\" -f2); do 
  grep "${f}" $2 | cut -d\  -f2 ; 
done | paste -sd+ | bc ) }
#
#SOLDIR=~/corpus/llvm_asan/${PROG}_llvm_asan_bitvectors/
#echo "${PROG}"
#echo "distillation, #, size, time"
#echo "M-U, $(grep "solution_size" ${SOLDIR}/${PROG}_moonshine_solution.json | cut -d\" -f4 ), $(FS ${PROG} ""), $(FT ${PROG} "")"
#echo "M-S, $(grep "solution_size" ${SOLDIR}/${PROG}_moonshine_size_solution.json | cut -d\" -f4), $(FS ${PROG} "_size"), $(FT ${PROG} "_size")"
#echo "M-T, $(grep "solution_size" ${SOLDIR}/${PROG}_moonshine_time_solution.json | cut -d\" -f4), $(FS ${PROG} "_time"), $(FT ${PROG} "_time")"
echo ${SOLFILE} ${TIMEWEIGHT} ${SIZEWEIGHT}
echo "#, size, time"
echo "$(grep ".bv" ${SOLFILE} | wc -l), $(FS ${SOLFILE} ${SIZEWEIGHT}) , $(FT ${SOLFILE} ${TIMEWEIGHT})"
