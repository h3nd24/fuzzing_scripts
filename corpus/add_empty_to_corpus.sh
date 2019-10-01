#!/bin/bash

# Simple script to create another corpus from existing corpus + empty seed.
# This is mainly used to the corpus generation of the experiments of adding empty seed into the corpus

EMPTY_DIR=${1}
SOURCE_DIR=${2}
TARGET_DIR=${3}
FILE_EXTENSION=${4}

mkdir ${TARGET_DIR}
for f in $(ls -1 ${SOURCE_DIR}); do ln -v ${SOURCE_DIR}/${f} ${TARGET_DIR}/; done

echo "Adding empty"
# There should be only one file in the empty directory, otherwise it does not make any sense.
md5sum ${EMPTY_DIR}/* | awk -v td="${TARGET_DIR}" -v ext="${FILE_EXTENSION}" '{system("ln -v "$2" "td"/"$1""ext)}'
