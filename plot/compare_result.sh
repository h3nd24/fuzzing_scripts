#!/bin/bash
# Simple script to compare the number of bugs (result of time_to_find.py, default to "_AUC" files)
# TAGS=compare_result

PROG=${1}
INFIX=${2}
LEFT=${3}
RIGHT=${4}

paste -d"\t" <(cut -d"," -f2 plot_data_stats/${PROG}_18h_${INFIX}_${LEFT}_AUC) <(cut -d"," -f2 plot_data_stats/${PROG}_18h_${INFIX}_${RIGHT}_AUC)
