#!/bin/bash

# Wrapper for add_empty_to_corpus.sh, basically applied to all existing corpora
PROG=${1}           # target e.g., "pdf"
FILE_EXTENSION=${2} # the file extension for the empty seed. Running md5sum on the empty seed removes the file extension e.g., ".pdf"

./add_empty_to_corpus.sh ${PROG}_empty_llvm_asan ${PROG}_moonshine_size_llvm_asan ${PROG}_mls_w_e_llvm_asan ${FILE_EXTENSION};
./add_empty_to_corpus.sh ${PROG}_empty_llvm_asan ${PROG}_moonshine_time_llvm_asan ${PROG}_mlt_w_e_llvm_asan ${FILE_EXTENSION};
./add_empty_to_corpus.sh ${PROG}_empty_llvm_asan ${PROG}_moonshine_llvm_asan      ${PROG}_mlu_w_e_llvm_asan ${FILE_EXTENSION};
./add_empty_to_corpus.sh ${PROG}_empty_llvm_asan ${PROG}_minset_llvm_asan         ${PROG}_msu_w_e_llvm_asan ${FILE_EXTENSION};
./add_empty_to_corpus.sh ${PROG}_empty_llvm_asan ${PROG}_cmin_llvm_asan           ${PROG}_c_w_e_llvm_asan   ${FILE_EXTENSION};
./add_empty_to_corpus.sh ${PROG}_empty_llvm_asan ${PROG}_full_llvm_asan           ${PROG}_f_w_e_llvm_asan   ${FILE_EXTENSION};
# for random it is a bit special, we need to insert empty seed to each of the random corpus
for i in {1..30}; do ./add_empty_to_corpus.sh ${PROG}_empty_llvm_asan ${PROG}_random_${i}_llvm_asan ${PROG}_r${i}_w_e_llvm_asan ${FILE_EXTENSION}; done
