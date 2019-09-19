#!/bin/bash

# Script to check the timeout of a particular seed.
# Works by registering the timing of individual runs and then average them (25x)

#set -x
#set -e

COMMAND=${1} # The prefix for the file containing the environment variables
DIR=${2}     # The corpus directory
source ~/llvm_asan/${COMMAND}_env

ITERATION=25
##BASE_DIR=${HOME}/llvm_asan

ulimit -v $[ LIMIT_MB << 10 ]

echo "${COMMAND} ${DIR}"
if [ ! -d ".intermediate" ]; then mkdir .intermediate; fi
if [ ! -d ".intermediate/${DIR}" ]; then mkdir .intermediate/${DIR}; fi
LOOP_ITER=$(seq 1 ${ITERATION})
export LD_LIBRARY_PATH=${PROG_LIB}

for f in ${DIR}/*; do
  echo -n "checking ${f}"
  f_int=.intermediate/${DIR}/$(basename ${f})
  if [ -f ${f_int} ]; then rm ${f_int}; fi
  ${PROG_BIN} ${PROG_PREFIX} ${f} ${PROG_POSTFIX} &> /dev/null
  EXIT_STATUS=$? 
  if [ "${EXIT_STATUS}" -ne "0" ]; then echo "${f} ${EXIT_STATUS}" >> ${DIR}_error; fi

  for i in ${LOOP_ITER}; do 
    echo $( ( time ${PROG_BIN} ${PROG_PREFIX} ${f} ${PROG_POSTFIX} ) 2>&1 | \
      tail -n 3 | grep --color=never -e "user" -e "sys" | \
      awk '{split($2,a,"m"); split(a[2],b,"s"); print b[1]*1000}' | \
      paste -s -d+ | bc ) >> ${f_int}
  done
  echo " TIME: "$(echo "scale=4; $(paste -s -d+ ${f_int} | bc) / ${ITERATION}" | bc)
done
