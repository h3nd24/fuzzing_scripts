#!/bin/bash

INPUT=${1}
OUTPUT=${2}

convert           \
   -verbose       \
   -density 150   \
   -trim          \
    ${INPUT}      \
   -quality 100   \
   -flatten       \
   -sharpen 0x1.0 \
    ${OUTPUT}
