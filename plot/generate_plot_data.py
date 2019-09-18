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

parser = argparse.ArgumentParser(description="Produce plot data for coverage and crashes vs. executions. Currently we disable the one for raw crashes because we do not use it for the paper.")
parser.add_argument('-i', '--input', metavar='Dir', type=str, help='Fuzzing run directory', default="")
parser.add_argument('-o', '--output', help="plot data prefix", default="plot_data")
parser.add_argument('-m', '--max-trial', default=0, help="the highest number of trial")
parser.add_argument('--execs-cap', default=sys.maxint, help="cap on number of executions")
parser.add_argument('--time-cap', default=sys.maxint, help="cap on time")
parser.add_argument('--num-fuzzers', default=8, help="the number of fuzzers involved in an experiment")
parser.add_argument('--algs', default="cmin moonshine", \
	help="space delimited algorithms for plot (e.g., cmin, moonshine, etc), default to 'cmin moonshine'")
args = parser.parse_args()

cwd = os.getcwd()
base_dir = os.path.join(cwd, args.input)
output = args.output
algs = args.algs.split(" ")
num_algs = len(algs)
num_fuzzers = int(args.num_fuzzers)
max_trial = int(args.max_trial)
execs_cap = float(args.execs_cap)
time_cap = int(args.time_cap)

print base_dir
print args

#####################################################################################################

# processing a csv file (plot_data)
def getData(file_name):
	fuzzer_info = []
	with open(file_name, 'rb') as csvfile:
		reader = csv.DictReader(csvfile, skipinitialspace=True)
		for row in reader:
			fuzzer_info.append( [int(row['# unix_time']), float(row['total_execs']), \
				float(row['map_size'][:-1]) , int(row['unique_crashes']) ]  )
	return fuzzer_info

# combining the data into data points for the figures
def getPlotData(base_dir):
	# read the plot_data from the 8 fuzzers
	plot_data = []
	for i in xrange(num_fuzzers):
		plot_data.append( getData(os.path.join(base_dir,"fuzzer%02d" % (i + 1),"plot_data")) )

	# initialization
	time_queue = PriorityQueue()
	lengths   =[0, 0, 0, 0, 0, 0, 0, 0]
	last_execs=[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	last_crash=[0, 0, 0, 0, 0, 0, 0, 0]
	last_mapsz=[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	last_row_index=[-1, -1, -1, -1, -1, -1, -1, -1]
	last_time=[0, 0, 0, 0, 0, 0, 0, 0]
	current_execs = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	current_mapsz = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	current_crash = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	start_time = plot_data[0][0][0]
	len_all = 0

	for i in xrange(8):
		time_queue.put( (plot_data[i][0][0], i) )
		lengths[i] = len(plot_data[i])
		if (plot_data[i][0][0] < start_time):
			start_time = plot_data[i][0][0]

	len_all = sum(lengths)
	time_data  = []
	execs_data = []
	mapsz_data = []
	crash_data = []

	last_added_execs = 0.0

	# keep processing until queue is empty or the number of execution is capped
	while not time_queue.empty():
		# get the current entry and update values accordingly
		current_time, current_id = time_queue.get()
		if current_time - start_time > time_cap:
			break
		row_index = last_row_index[current_id] + 1
		row = plot_data[current_id][row_index]
		last_row_index[current_id] += 1
		last_execs[current_id] = current_execs[current_id] = row[1]
		last_mapsz[current_id] = current_mapsz[current_id] = row[2]
		last_crash[current_id] = current_crash[current_id] = row[3]
		last_time[current_id] = current_time

		# smooth the values for the  other fuzzers
		for i in xrange(8):
			# the value for the current fuzzer is already updated, so skip
			if i == current_id:
				continue
			fuzzer_row_index = last_row_index[i]
			# only process if the fuzzer has finished reading the initial corpus
			if fuzzer_row_index == -1:
				continue
			next_row = fuzzer_row_index + 1
			# smooth the values based on the elapsed time w.r.t. the timing of this other fuzzer
			if next_row < lengths[i]:
				next_time, next_execs, next_mapsz, next_crash = plot_data[i][next_row]
				smoothing_factor = float(current_time - last_time[i]) / float(next_time - last_time[i])
				last_execs_i = last_execs[i]
				last_mapsz_i = last_mapsz[i]
				last_crash_i = last_crash[i]
				current_execs[i] = smoothing_factor * float(next_execs - last_execs_i) + last_execs_i
				current_mapsz[i] = smoothing_factor * float(next_mapsz - last_mapsz_i) + last_mapsz_i
				current_crash[i] = smoothing_factor * float(next_crash - last_crash_i) + last_crash_i
				
		total_execs = sum(current_execs)

		# break if execution cap is reached
		if total_execs > execs_cap:
			break

		# only add data points that have distinguishable total executions. 
		# Otherwise simps function will complain division by zero
		if total_execs == last_added_execs:
			execs_data[-1] = total_execs
			crash_data[-1] = sum(current_crash)
			mapsz_data[-1] = max(current_mapsz)
		else:
			time_data.append(current_time - start_time)
			execs_data.append(total_execs)
			crash_data.append(sum(current_crash))
			mapsz_data.append(max(current_mapsz))
		last_added_execs = total_execs
		
		# add the next entry into the priority queue
		if row_index + 1 < lengths[current_id]:
			time_queue.put( (plot_data[current_id][row_index + 1][0], current_id) )
		
	return (execs_data, mapsz_data, crash_data, time_data)

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

# the significant index is useful to give the option of sorting according to either iteration or time
def getAveragePlot(plot_data, significant_index, significant_interval):
	exp_num = len(plot_data)
	
	# initialization
	ordering_queue = PriorityQueue()
	lengths   = [0] * exp_num
	execs     = [0.0] * exp_num
	crash     = [0.0] * exp_num
	mapsz     = [0.0] * exp_num
	time      = [0] * exp_num
	last_row_index = [-1] * exp_num
        key_threshold = 0
	len_all = 0

	for i in xrange(exp_num):
		ordering_queue.put( (plot_data[i][significant_index][0], i) )
		lengths[i] = len(plot_data[i][0])

	len_all        = sum(lengths)
	time_data      = []
	execs_data     = []
	mapsz_data     = []
	crash_data     = []
#        geo_crash_data = []
#        geo_mapsz_data = []
	
        elements = 0.0

	# keep processing until queue is empty or the number of execution is capped
	while not ordering_queue.empty():
		# get the current entry and update values accordingly
		current_key, current_id = ordering_queue.get()
		row_index = last_row_index[current_id] + 1
		if row_index == 0:
			elements += 1.0
		row = plot_data[current_id]
		execs[current_id] = row[0][row_index]
		mapsz[current_id] = row[1][row_index]
		crash[current_id] = row[2][row_index]
		time[current_id]  = row[3][row_index]
		last_row_index[current_id] = row_index
		if (current_key >= key_threshold): 
		    total_execs = execs[current_id]
		    execs_data.append(total_execs)
		    crash_data.append(arithmetic_mean(crash, elements) )
		    mapsz_data.append(arithmetic_mean(mapsz, elements) )
		    time_data.append(time[current_id])
                    key_threshold += significant_interval
#                    geo_crash_data.append(geometric_mean(crash, elements) )
#                    geo_mapsz_data.append(geometric_mean(mapsz, elements) )
		
		# add the next entry into the priority queue
		if row_index + 1 < lengths[current_id]:
			ordering_queue.put( (row[significant_index][row_index + 1], current_id) )

                if ordering_queue.empty():
		    total_execs = execs[current_id]
		    execs_data.append(total_execs)
		    crash_data.append(arithmetic_mean(crash, elements) )
		    mapsz_data.append(arithmetic_mean(mapsz, elements) )
		    time_data.append(time[current_id])
		
#	return (execs_data, mapsz_data, crash_data, time_data, geo_crash_data, geo_mapsz_data)
	return (execs_data, mapsz_data, crash_data, time_data)

print "collecting data ... " 

plot_data = []
for alg_idx in xrange(num_algs):
	plot_data.append([])

sys.stdout.write("progress: 0 / %d (%.2f)\n" % (max_trial, 0.0))
start_time = time.time()
for i in xrange(1, max_trial + 1):
	for alg_idx in xrange(num_algs):
		plot_data[alg_idx].append(getPlotData(os.path.join(base_dir, "%s_%d" % (algs[alg_idx], i) )))
	sys.stdout.write("\033[1A\033[K")
	sys.stdout.write("progress: %d / %d (%.2f%%) %.2fs\n" % (i, max_trial, \
		float(i) * 100.0 / float(max_trial), time.time() - start_time))
	
for alg_idx in xrange(num_algs):
	counter = 1	
	for exp in plot_data[alg_idx]:
                # crash plot data
#		with open(output + "_crashes_%s_%d" % (algs[alg_idx], counter), "w") as f:
#			f.write("Iteration,num_crashes,time\n")
#			length = len(exp[0])
#			for i in xrange(length):
#				f.write("%f,%f,%f\n" % (exp[0][i], exp[2][i], exp[3][i]))

                # coverage plot data
                with open(output + "_coverage_%s_%d" % (algs[alg_idx], counter), "w") as f:
			f.write("Iteration,map_size,time\n")
			length = len(exp[0])
			for i in xrange(length):
				f.write("%f,%f,%f\n" % (exp[0][i], exp[1][i], exp[3][i]))
		counter += 1


print "getting average execs data"

for alg_idx in xrange(num_algs):
#	avg_execs, avg_mapsz, avg_crash, avg_time, geo_avg_crash, geo_avg_mapsz = getAveragePlot(plot_data[alg_idx], 0)
	avg_execs, avg_mapsz, avg_crash, avg_time = getAveragePlot(plot_data[alg_idx], 0, 10000)
        # average crashes
#	with open(output + "_crashes_%s_avg" % (algs[alg_idx]), "w") as f:
#		f.write("Iteration,num_crashes,time\n")
#		length = len(avg_execs)
#		for i in xrange(length):
#			f.write("%f,%f,%f\n" % (avg_execs[i], avg_crash[i], avg_time[i]))
	# average coverage
        with open(output + "_coverage_%s_avg" % (algs[alg_idx]), "w") as f:
		f.write("Iteration,map_size,time\n")
		length = len(avg_execs)
		for i in xrange(length):
			f.write("%f,%f,%f\n" % (avg_execs[i], avg_mapsz[i], avg_time[i]))

#	with open(output + "_%s_execs_geo_avg" % (algs[alg_idx]), "w") as f:
#		f.write("Iteration,map_size,num_crashes,time\n")
#		length = len(avg_execs)
#		for i in xrange(length):
#			f.write("%f,%f,%f,%f\n" % (avg_execs[i], geo_avg_mapsz[i], geo_avg_crash[i], avg_time[i]))

##print "getting average time data"
##
##for alg_idx in xrange(num_algs):
##	avg_execs, avg_mapsz, avg_crash, avg_time = getAveragePlot(plot_data[alg_idx], 3)
##	#moonshine_avg_execs, moonshine_avg_mapsz, moonshine_avg_crash, moonshine_avg_time = getAveragePlot(data_moonshine, 3, 36)
##
##	with open(output + "_%s_time_avg" % (algs[alg_idx]), "w") as f:
##		f.write("Iteration,map_size,num_crashes,time\n")
##		length = len(avg_execs)
##		for i in xrange(length):
##			f.write("%f,%f,%f,%f\n" % (avg_execs[i], avg_mapsz[i], avg_crash[i], avg_time[i]))

