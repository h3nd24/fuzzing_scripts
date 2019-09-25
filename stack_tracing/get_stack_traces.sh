#!/bin/bash

# Script to execute the binary with the crashes found in a fuzzer campaign.
# If the binary crashes, then we get the stack traces from the core dump.
# The number of fuzzers is stil fixed at the moment (eight-fuzzers).

DIR=${2}         # The fuzzer output directory, e.g., cmin_1
PROG_CONFIG=${1} # Program config / environment variables
source ${PROG_CONFIG}

if [ ! -d "stack_traces" ]; then mkdir stack_traces; fi
if [ ! -d "stack_traces/${DIR}" ]; then mkdir stack_traces/${DIR}; fi
#if [ -f "non_crashing_${DIR}" ]; then rm non_crashing_${DIR}; fi
TOTAL=$(ls ${DIR}/fuzzer*/crashes/id* | wc -l)
export ASAN_OPTIONS=abort_on_error=1:detect_leaks=0:symbolize=0:allocator_may_return_null=1
for i in {1..8}; do
  echo "  Processing fuzzer0${i}"
  if [ ! -d "stack_traces/${DIR}/fuzzer0${i}" ]; then 
    mkdir stack_traces/${DIR}/fuzzer0${i}; 
    mkdir stack_traces/${DIR}/fuzzer0${i}/crashes; 
  fi
  for f in $(ls ${DIR}/fuzzer0${i}/crashes/id*); do
    FN=$(basename ${f})
    echo -n "    Processing ${FN} ... "
    # skip if the stack tracing has been done. This is so that we can do "staged" stack tracing
    if [ ! -f "stack_traces/${DIR}/fuzzer0${i}/crashes/${FN}" ]; then
      # execute the input file
      cp ${f} ${DIR}/fuzzer0${i}/.csh_input${FILE_EXTENSION};
      (ulimit -c unlimited; ulimit -Sv $[ LIMIT_MB << 10 ]; rm -f core; \
        LD_LIBRARY_PATH=${PROG_LIB} timeout 3.5s ${PROG_BIN} ${PROG_PREFIX} \
        ${DIR}/fuzzer0${i}/.csh_input${FILE_EXTENSION} ${PROG_POSTFIX} ) &> /dev/null
      # if it produces core dump then take the stack hashes
      if [ -f "core" ]; then
        echo "crashing"
        $(LD_LIBRARY_PATH=${PROG_LIB} gdb -q --batch \
          -ex "bt" ${PROG_BIN} core 2>&1 | grep "#" | uniq > stack_traces/${DIR}/fuzzer0${i}/crashes/${FN} )
        rm -f core
      else # in the case that the file is not crashing, then log the file name
        echo "non-crashing"
        touch "stack_traces/${DIR}/fuzzer0${i}/crashes/${FN}"
        echo "${DIR}/fuzzer0${i}/crashes/${FN}" >> non_crashing_stack_trace_${DIR}
      fi
    else
      echo "skipping"
    fi
  done
done
