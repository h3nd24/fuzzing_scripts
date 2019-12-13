#!/bin/bash

# A script that converts the process raw data into coverage information.
# The binary needs to be compiled by following the instruction from 
# https://clang.llvm.org/docs/SourceBasedCodeCoverage.html (-fprofile-instr-generate -fcoverage-mapping).

LLVM_PROFDATA=${LLVM_PROFDATA:-"llvm-profdata"}
LLVM_COV=${LLVM_COV:-"llvm-cov"}
ENV_DIR=${ENV_DIR:-"/home/hendrag/llvm_asan"}
if [ ! -d "${ENV_DIR}" ]; then echo "${ENV_DIR} does not exist"; exit 1; fi
if [ ! -e "${LLVM_PROFDATA}" ]; then echo "${LLVM_PROFDATA} does not exist"; exit 1; fi
if [ ! -e "${LLVM_COV}" ]; then echo "${LLVM_COV} does not exist"; exit 1; fi

PROG=${1}
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
