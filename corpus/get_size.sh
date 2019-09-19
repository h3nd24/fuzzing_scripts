#!/bin/bash

# Simple script to get the size of each individual seed in a corpus
set -x
DIR=${1}
ls -Ll ${DIR} | awk '{print $9","$5}' > ${DIR}_size
