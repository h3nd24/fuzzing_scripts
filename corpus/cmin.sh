#!/bin/bash

# Wrapper script to call afl-cmin based on our environment variables

set -x

TARGET=${1} # Target program, used to load the environment variables
DIR=${2}    # The directory of the source corpus
PROG_CONFIG=~/llvm_asan/${TARGET}_env
if [ ! -f ${PROG_CONFIG} ]; then echo "${PROG_CONFIG} does not exists"; exit 1; fi

source ${PROG_CONFIG}
OUT_DIR=${PROG}_cmin_llvm_asan
TMPFILE=.cur_input_${PROG}_llvm_asan${FILE_EXTENSION}

AFL_KEEP_TRACES=1 LD_LIBRARY_PATH=${PROG_LIB} \
~/afl-2.52b/afl-cmin -m ${LIMIT_MB} -i ${DIR} -o ${OUT_DIR} -f ${TMPFILE} -- ${PROG_BIN} ${PROG_PREFIX} @@ ${PROG_POSTFIX}

