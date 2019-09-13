import csv
import os
import shutil
import glob
import argparse
import matplotlib.pyplot as plt
from Queue import PriorityQueue
from scipy.integrate import simps
from scipy import stats
import sys
import time

parser = argparse.ArgumentParser(description="Getting average from deduplicated data, either stack-hash deduplicated or bug triaging. In practice, this script takes the output from either time_to_find.py or deduplicated.py as input.")
parser.add_argument('-e', '--experiment', help="corpus treatment / distillation, e.g., \"cmin\"")
parser.add_argument('-i', '--input', metavar='Dir', type=str, help='where the plot data is located, e.g., \"dedup_plot_data\"', default=".")
parser.add_argument('--prefix', help="input file prefix, e.g., \"pdf_18h_bug_crashes\"")
parser.add_argument('-o', '--output', help="output filename")
parser.add_argument('-m', '--max-trial', default=30, help="the highest number of trial, default is \"30\"")

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
			fuzzer_info.append( [int(row['Iteration']), int(row['num_crashes']) ]  )
	return fuzzer_info


# combining the data into data points for the figures

def arithmetic_mean(arr, n):
    return sum(arr) / n

def geometric_mean(arr, n):
    if len(arr) > n:
      arr_cpy = arr[:]
      while True:
        if len(arr_cpy) > n:
          arr_cpy.remove(0.0)
        else:
          break
      return stats.gmean(arr_cpy)
    else:
      return stats.gmean(arr)

def getAveragePlot(plot_data):
	# read the plot_data from the 8 fuzzers
	exp_num = len(plot_data)
	
	# initialization
	ordering_queue = PriorityQueue()
	lengths   = [0] * exp_num
	execs     = [0.0] * exp_num
	crash     = [0.0] * exp_num
	last_row_index = [-1] * exp_num

	for i in xrange(exp_num):
		ordering_queue.put( (plot_data[i][0][0], i) )
		lengths[i] = len(plot_data[i])

	avg_data = []
	avg_data.append([0,0.0])
        elements = float(exp_num)

	# keep processing until queue is empty or the number of execution is capped
	while not ordering_queue.empty():
		# get the current entry and update values accordingly
		current_execs, current_id = ordering_queue.get()
		row_index = last_row_index[current_id] + 1
#		if row_index == 0:
#			elements += 1.0
		exp_data = plot_data[current_id]
                total_execs = exp_data[row_index][0]
		crash[current_id] = exp_data[row_index][1]
		last_row_index[current_id] = row_index
		avg_data.append([total_execs, arithmetic_mean(crash, elements)] )		
		
		# add the next entry into the priority queue
		if row_index + 1 < lengths[current_id]:
			ordering_queue.put( (exp_data[row_index + 1][0], current_id) )
		
	return avg_data

plot_data = []
sys.stdout.write("progress: 0 / %d (%.2f)\n" % (max_trial, 0.0))
start_time = time.time()
for i in xrange(1, max_trial + 1):
	plot_data.append(getData(os.path.join(base_dir, "%s_%s_%d" % (prefix,experiment, i) )))
	sys.stdout.write("\033[1A\033[K")
	sys.stdout.write("progress: %d / %d (%.2f%%) %.2fs\n" % (i, max_trial, \
		float(i) * 100.0 / float(max_trial), time.time() - start_time))
	

print "getting average execs data"

avg_data = getAveragePlot(plot_data)

with open(output, "w") as f:
	f.write("Iteration,num_crashes\n")
	for row in avg_data:
		f.write("%f,%f\n" % (row[0],row[1]))

