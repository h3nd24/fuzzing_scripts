import csv
import sys
import argparse
import numpy as np

# TAGS: coefficient_of_variation

parser = argparse.ArgumentParser( \
	description="calculate Coefficient of Variation. This is deprecated since we don't use it anymore in the paper")
parser.add_argument('-i', '--input', type=str, help='Takes the output of calculate_AUC.R, e.g., \"plot_data_stats/pdf_18h_bug_crashes_cmin_AUC\"')
args = parser.parse_args()

crashes = []
auc = []
with open(args.input, 'rb') as csvfile:
  reader = csv.DictReader(csvfile, skipinitialspace=True)
  for row in reader:
    crashes.append(int(row['num_crashes']))
    auc.append(int(row['num_crashes_AUC']))

np_crashes = np.array(crashes)
np_auc = np.array(auc)
#sys.stdout.write("(%0.2f %0.2f) (%0.2f %0.2f)\n" % (np.std(np_crashes, ddof=1), np.mean(np_crashes), np.std(np_auc, ddof=1), np.mean(np_auc)))    
crashes_mean = np.mean(np_crashes)
if crashes_mean == 0:
  sys.stdout.write("N/A")
else:
  sys.stdout.write("%0.2f" % ((np.std(np_crashes, ddof=1)) / crashes_mean))
sys.stdout.write(" & ")
auc_mean = np.mean(np_auc)
if auc_mean == 0:
  sys.stdout.write("N/A ")
else:
  sys.stdout.write("%0.2f " % ((np.std(np_auc, ddof=1)) / auc_mean))
sys.stdout.write("%0.2f & %0.2f\n" % ((np.std(np_crashes, ddof=1)) / (np.mean(np_crashes)), ((np.std(np_auc, ddof=1)) / (np.mean(np_auc))) ) )
