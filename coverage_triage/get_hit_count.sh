#!/bin/bash

# A simple script that parse the hit count from a particular line of a particular file.

DIR=${1} # Coverage directory as a result of get_source_profile.sh
# Example: jdmarker.c:659 for jpeg-turbo
FILE=${2} # source file of interest: jdmarker.c
LINE=${3} # line of code of interest: 659

ACTUAL_LOC=$(find ${DIR} -name "${FILE}.txt")
if [ -z "${ACTUAL_LOC}" ]; then echo "${FILE}.txt is not found within ${DIR}"; exit 1; fi
grep "^ *${LINE}|"  $(find . -name "${FILE}.txt" ) | awk -F"|" '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
