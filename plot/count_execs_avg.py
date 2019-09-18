import csv
import os
import shutil
import glob
import argparse
from Queue import PriorityQueue
import numpy as np
import sys
import time

parser = argparse.ArgumentParser(description="Getting average from the seed stats (execs and paths), i.e., the output of \"count_execs.py\" for all trial. The input format will be of the form \"<prefix>_<experiment>_<n>.csv\" where 1 <= n <= <max_trial>")
parser.add_argument('-e', '--experiment', help="corpus treatment / distillation, e.g., cmin")
parser.add_argument('-i', '--input', metavar='Dir', type=str, help='where the the outputs from \"count_execs.py\" are located', default=".")
parser.add_argument('--prefix', help="input file prefix, e.g., \"sox\"")
parser.add_argument('-o', '--output', help="output filename which will be used further by \"plot_seed_stats_grouped.R\"")
parser.add_argument('-m', '--max-trial', default=0, help="the highest number of trial")

args = parser.parse_args()

cwd = os.getcwd()
base_dir = os.path.join(cwd, args.input)
prefix = args.prefix
output = os.path.join(cwd, args.output)
experiment = args.experiment
max_trial = int(args.max_trial)

#####################################################################################################

# processing a csv file (plot_data)
def getData(file_name):
	fuzzer_info = []
	with open(file_name, 'rb') as csvfile:
		reader = csv.DictReader(csvfile, skipinitialspace=True)
		for row in reader:
			fuzzer_info.append( [row['seed'], int(row['execs']), int(row['paths']) ]  )
	return fuzzer_info


# combining the data (average)
def combineStats(aggregate_execs, aggregate_paths, plot_data):
  for seed_stats in plot_data:
    for rows in seed_stats:
      if rows[0] not in aggregate_execs:
        aggregate_execs[ rows[0] ] = []
        aggregate_execs[ rows[0] ].append(rows[ 1 ])
      else:
        aggregate_execs[ rows[0] ].append(rows[ 1 ])

      if rows[0] not in aggregate_paths:
        aggregate_paths[ rows[0] ] = []
        aggregate_paths[ rows[0] ].append(rows[ 2 ])
      else:
        aggregate_paths[ rows[0] ].append(rows[ 2 ])

plot_data = []
sys.stdout.write("progress: 0 / %d (%.2f)\n" % (max_trial, 0.0))
start_time = time.time()
for i in xrange(1, max_trial + 1):
	plot_data.append(getData(os.path.join(base_dir, "%s_%s_%d.csv" % (prefix,experiment, i) )))
	sys.stdout.write("\033[1A\033[K")
	sys.stdout.write("progress: %d / %d (%.2f%%) %.2fs\n" % (i, max_trial, \
		float(i) * 100.0 / float(max_trial), time.time() - start_time))

print "getting average execs data"

aggregate_execs = {}
aggregate_paths = {}
avg_data = combineStats(aggregate_execs, aggregate_paths, plot_data)

with open(output, "w") as f:
  f.write("seed,execs,sd_execs,paths,sd_paths\n")
  for (key, value) in aggregate_execs.iteritems():
    execs_data = np.array(value)
    paths_data = np.array(aggregate_paths[key])
#    print str(paths_data)
#    print str(execs_data)
    f.write( key + "," + str(np.mean(execs_data)) + "," + str(np.std(execs_data)) + "," + \
      str(np.mean(paths_data)) + "," + str(np.std(paths_data)) + "\n" )

