#!/bin/bash
#set -x

# Helper script to ease the gathering of AFL tuples using afl-showmap.

DIR=${1}         # The directory which files will be used as the inputs to afl-showmaps.
PROG=${2}        # Target
CONFIG_ARGS=${3} # if there is any arguments to the program config / environment variables
PROG_CONFIG=~/llvm_asan/${PROG}_env
if [ ! -f ${PROG_CONFIG} ]; then echo "${PROG_CONFIG} does not exists"; exit 1; fi

source ${PROG_CONFIG} ${CONFIG_ARGS}
OUT_DIR=${PROG}_llvm_asan_tuples
if [ ! -d ${OUT_DIR} ]; then mkdir ${OUT_DIR}; fi

SHOWMAP_FLAGS="-e -q -m ${LIMIT_MB}"
if [ ! -z ${TIME_LIMIT} ]; then SHOWMAP_FLAGS=${SHOWMAP_FLAGS}" -t ${TIME_LIMIT}"; fi
CUR=0
TOTAL=$(ls ${DIR} | wc -l)
for f in ${DIR}/*; do
  printf "\\r Processing input ${CUR}/${TOTAL}"
  LD_LIBRARY_PATH=${PROG_LIB} \
    ~/afl-2.52b/afl-showmap ${SHOWMAP_FLAGS} -o ${OUT_DIR}/afltuples-$(basename ${f}) -- \
      ${PROG_BIN} ${PROG_PREFIX} ${f} ${PROG_POSTFIX}
  CUR=$((CUR + 1))
done
