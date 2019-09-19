set -x

# Wrapper script to simplify calling MoonLight for various targets and weighting

p=${1}
t=moonlight
WEIGHT=${2}
NAME=${p}_${t}
if [ ! -z "${WEIGHT}" ]; then WEIGHTED_OPT="-w ${p}_${WEIGHT}_weight"; NAME=${p}_${t}_${WEIGHT}; fi
moonshine -i -d ${p}_llvm_asan_bitvectors -n ${NAME} -m ${NAME} ${WEIGHTED_OPT}
