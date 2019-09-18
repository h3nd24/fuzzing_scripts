#!/bin/bash
# This helper script is used to format the output of VD.A from produce_vda_table.py so that it can be copy and pasted directly to the Latex file.
# The input is the output log from the plot.R (or wrapped by generate_bug_plot_data.sh). 
# A small caveat is that the plot.R must be invoked while also including the table of conclusions.

PROG=${1}
LOG_FILE=${2}
INT_FILE=${3} # intermediate file of grabbing the necessary information from the output log of plot.R

(echo "value_type,winner,loser,estimate,magnitude" && \
  awk 'BEGIN{flag=0} {if ($0 !~ /###################/ && flag) print $0; if ($0 ~ /###################/) {flag=!flag }}' ${LOG_FILE} ) > ${INT_FILE}

# 3 baselines: CMIN, MINSET, and Rand
python produce_vda_table.py -i ${INT_FILE} --base "cmin" --target "${PROG}" --algs "moonshine moonshine_size moonshine_time empty full minset random"
python produce_vda_table.py -i ${INT_FILE} --base "minset" --target "${PROG}" --algs "moonshine moonshine_size moonshine_time empty full cmin random"
python produce_vda_table.py -i ${INT_FILE} --base "random" --target "${PROG}" --algs "moonshine moonshine_size moonshine_time empty full cmin minset" 

#python produce_vda_table.py -i ${INT_FILE} -o ${OUT_FILE}_baselines --base "minset" --target "${PROG}" --algs "cmin random"
