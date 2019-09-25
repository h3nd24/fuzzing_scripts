#!/bin/bash

# TAGS: libtiff, libxml, FreeType
#set -x
# Script to run a particular crash in the "similar" context as during the fuzzing process.
# This is actually used during triage to check if we can generate a core dump from executing the crashing seed.
# "similar" in this case leaves room for the difference in the absolute path for executing the seed and binaries.
# The expectation is that if we run it in "similar" context then we can actually crash using the seed provided.

TARGET=${1}    # The target, e.g,, pdf
EXP_DIR=${2}   # The directory of the fuzzing experiment
FUZZER_ID=${3} # The fuzzer ID, i.e., 1 <= FUZZER_ID <= 8 since we limit to 8 fuzzers
CRASH_ID=${4}  # The id of the crashing seed, since AFL enumerate the crashing seed in the form of "id:<n>,..." where n is a 6 digit identifier

source ~/llvm_asan/${TARGET}_env        # Load the program environment

printf -v CRASH_ID "%06d" ${CRASH_ID}   # Make six digit 0-appended crash ID
printf -v FUZZER_ID "%02d" ${FUZZER_ID} # two digit 0-appended fuzzer ID
FUZZER_NAME=fuzzer${FUZZER_ID}

# Copy the crashing seed into temporary file
INPUTFILE=${EXP_DIR}/${FUZZER_NAME}/.cra_input${FILE_EXTENSION}
CRASH_FILE=${EXP_DIR}/${FUZZER_NAME}/crashes/id:${CRASH_ID}*
if [ ! -f ${CRASH_FILE} ]; then echo "${CRASH_FILE} does not exist"; exit ; fi

cp ${CRASH_FILE} ${INPUTFILE}   # To make it more similar to the one during fuzzing experiment, where AFL copied the seed into temporary file
ulimit -c unlimited             # To enable core dump
ulimit -Sv $[ LIMIT_MB << 10 ]  # Setting the memory limit
  LD_LIBRARY_PATH=${PROG_LIB} \
    ASAN_OPTIONS=abort_on_error=1:detect_leaks=0:allocator_may_return_null=1:symbolize=1 \
    ${PROG_BIN} ${PROG_PREFIX} ${INPUTFILE} ${PROG_POSTFIX}

echo $?                         # Find out the exit status
echo "${PROG_BIN} ${INPUTFILE}" # Some information on the program binary used and the input file, mainly for diagnostic purpose

#fi
