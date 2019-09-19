set -x
# TAGS: clean_cmin
# This simple script is used to remove the intermediate files from processing afl-cmin (leaving the tuples themselves intact)
DIR=${1}/.traces/
rm ${DIR}/.all_uniq ${DIR}/.already_have ${DIR}/.candidate_list ${DIR}/.candidate_script ${DIR}/.link_test ${DIR}/.run_test
