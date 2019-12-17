#!/bin/bash

LLVM_PROFDATA=${LLVM_PROFDATA:-"llvm-profdata"}
LLVM_COV=${LLVM_COV:-"llvm-cov"}
ENV_DIR_DEFAULT=~/llvm_asan
ENV_DIR=${ENV_DIR:-"${ENV_DIR_DEFAULT}"}
if [ ! -d "${ENV_DIR}" ]; then echo "${ENV_DIR} does not exist"; exit 1; fi
command -v ${LLVM_PROFDATA} >/dev/null 2>&1 || { echo >&2 "I require foo but it's not installed.  Aborting."; exit 1; }
command -v ${LLVM_COV} >/dev/null 2>&1 || { echo >&2 "I require foo but it's not installed.  Aborting."; exit 1; }

PROG=${1}
#TYPE=${2}
#EXP_NUM=${3}
#FUZZER=${4}
#ID=${5}
FILENAME=${2} # the prefix to the profraw
source ${ENV_DIR}/${PROG}_env

printf -v EXP_NUM "%02d" ${EXP_NUM}
printf -v FUZZER "%02d" ${FUZZER}
printf -v ID "%06d" ${ID}
#FILENAME=${PROG}_${TYPE}_${EXP_NUM}_${FUZZER}_${ID}

if [ -d ${PROG}_coverage ]; then rm -rf ${PROG}_coverage; fi
${LLVM_PROFDATA} merge ${FILENAME}.profraw -o ${FILENAME}.profdata
#echo "${FILENAME}.profraw is processed into ${FILENAME}.profdata"
${LLVM_COV} show -output-dir=${PROG}_coverage -path-equivalence=/${PROG},`pwd`/${PROG}_src -instr-profile ${FILENAME}.profdata ${COV_BIN}
#echo "source coverage information is collected (${PROG}_coverage)"
