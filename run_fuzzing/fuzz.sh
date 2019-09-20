#!/bin/bash

# Wrapper script to ease the initiation of a single instance of a fuzzing experiment
set -x 

TARGET=${1}  # target, e.g., pdf
TYPE=${2}    # distillation technique, e.g., cmin
NUM_EXP=${3} # experiment number
FUZZER=${4}  # the fuzzer number in a parallel setting

PROG_CONFIG=~/llvm_asan/${TARGET}_env
if [ ! -f ${PROG_CONFIG} ]; then echo "${PROG_CONFIG} does not exist"; exit 1; fi
source ${PROG_CONFIG}

IN_DIR=~/corpus/llvm_asan/${PROG}/${PROG}_${TYPE}_llvm_asan
# only in the case of random we need to specify which corpus is used
if [ "${TYPE}" == "random" ]; then IN_DIR=~/corpus/llvm_asan/${PROG}/${PROG}_${TYPE}_${NUM_EXP}_llvm_asan; fi 
OUT_DIR="${TYPE}_${NUM_EXP}"
AFL_FUZZ=~/afl-2.52b/afl-fuzz

FUZZER_NAME=fuzzer0${FUZZER}
FUZZER_TYPE="-S"
if [ "${NUM}" -eq "1" ]; then FUZZER_TYPE="-M"; fi

AFL_ARGS="-m ${LIMIT_MB} -i ${IN_DIR} -o ${OUT_DIR}" 
AFL_ARGS=${AFL_ARGS}" -f ${OUT_DIR}/${FUZZER_NAME}/.cur_input${FILE_EXTENSION}"
if [ ! -z "${TIME_LIMIT}" ]; then AFL_ARGS=${AFL_ARGS}" -t ${TIME_LIMIT}"; fi

AFL_NO_UI=1 LD_LIBRARY_PATH=${PROG_LIB} \
  timeout 18h ${AFL_FUZZ} ${AFL_ARGS} ${FUZZER_TYPE} ${FUZZER_NAME} ${PROG_BIN} \
    ${PROG_PREFIX} @@ ${PROG_POSTFIX} 

