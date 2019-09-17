#!/bin/bash
# This is a helper script that calls calculate_CV.py.
# Mainly used to get the coefficient of variation in the Latex table format so I can copy and paste directly into the .tex file.
# Unfortunately this script is now deprecated since we do not use the coefficient of variation anymore in the paper.

declare -A EXPANDED_PROGS=( ["pdf"]="Poppler" \
  ["sox"]="SoX (MP3)" ["wav"]="SoX (WAV)" ["tiff409c710"]="libtiff" \
  ["ttf253"]="FreeType" ["xml290"]="libxml" )

for p in pdf sox wav tiff409c710 ttf253 xml290; do
  echo -n "${EXPANDED_PROGS[$p]} & "
  for t in cmin moonshine moonshine_size moonshine_time empty full minset; do
    python calculate_CV.py -i plot_data_stats/${p}_18h_bug_crashes_${t}_AUC
    echo -n "& "
  done
  python calculate_CV.py -i plot_data_stats/${p}_18h_bug_crashes_random_AUC
  echo "\\\\"
done
