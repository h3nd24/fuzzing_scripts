#!/bin/bash

# TAGS: libtiff
# Just like get_core.sh, but it is invoking GDB instead and removed the memory limit (inconsistent with the use of GDB).
# This is because there are no patches yet for the bugs, but we can tell that it triggers the bug through hit breakpoints in GDB.
# However, the gdb script for each bug will be different
DEBUG_ID=${2}  # Bug ID, i.e., "A", "B", and "C"
EXP_DIR=${3}   # Directory for the fuzzing experiment
FUZZER_ID=${4}
CRASH_ID=${5}

# almost hardcode for now
PROG_ENV=${1}
if [ "${DEBUG_ID}" == "B" ]; then PROG_ENV=${PROG_ENV}_debug; fi # for bug B, we need non-optimized (-O0) version of the binary
PROG_ENV=${PROG_ENV}_env
source ~/llvm_asan/${PROG_ENV}

printf -v CRASH_ID "%06d" ${CRASH_ID}   # six-digit 0-appended crash ID
printf -v FUZZER_ID "%02d" ${FUZZER_ID} # two-digit 0-appended fuzzer ID
FUZZER_NAME=fuzzer${FUZZER_ID}

# Copy the crashing seed to temporary file
INPUTFILE=${T}/${FUZZER_NAME}/.cra_input${FILE_EXTENSION}
CRASH_FILE=${T}/${FUZZER_NAME}/crashes/id:${CRASH_ID}*
if [ ! -f ${CRASH_FILE} ]; then echo "${CRASH_FILE} does not exist"; exit ; fi
cp ${CRASH_FILE} ${INPUTFILE}

# Invoke the GDB with script to debug a particular bug
LD_LIBRARY_PATH=${PROG_LIB} \
  ASAN_OPTIONS=abort_on_error=1:detect_leaks=0:allocator_may_return_null=1:symbolize=1 \
  gdb --batch -x debug_${DEBUG_ID} --args ${PROG_BIN} ${PROG_PREFIX} ${INPUTFILE} ${PROG_POSTFIX}

echo "${PROG_BIN} ${INPUTFILE}" # Diagnostic information about which binary is invoked and the crashing seed used
