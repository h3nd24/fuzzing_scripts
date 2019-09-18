import csv
import os
import shutil
import glob
import argparse
from Queue import PriorityQueue

def getData(file_name):
	fuzzer_info = []
	with open(file_name, 'rb') as csvfile:
		reader = csv.DictReader(csvfile, skipinitialspace=True)
		for row in reader:
			fuzzer_info.append( [int(row['# unix_time']), int(row['unique_crashes']), \
				int(row['total_execs']) ]  )
	return fuzzer_info

parser = argparse.ArgumentParser( \
	description="Output the combined data of 8 fuzzers for plotting, also output the first time a particular bug is found. The content of the crash files are expected to be the bug ID. The directory structure is expected to be <input>/<triage-dir>/<experiment>")
parser.add_argument('-i', '--input', type=str, help='Fuzzing run directory, e.g., pdf_18h')
parser.add_argument(      '--triage-dir', type=str, default="triage_output", help="output if triage result in the fuzzing run directory. Defaulted to \"triage_output\"")
parser.add_argument(      '--experiment', help="fuzzing experiment result (base fuzzer directory), e.g., cmin_1")
parser.add_argument('-o', '--output', help="output file")
parser.add_argument(      '--bug-stats', help="bug statistic file (output)", default="bug_stats")
parser.add_argument(      '--time-cap', default=64800, help="maximum time in an experiment")
args = parser.parse_args()

cwd = os.getcwd()
base_dir = os.path.join(cwd, args.input)
experiment = args.experiment
out_file = os.path.join(cwd, args.output)
bug_stats_file = os.path.join(cwd, args.bug_stats)
time_cap = int(args.time_cap)
triage_dir = args.triage_dir

print args

stack_hashes = set()
current_crashes = 0

def get_stack_hash(base_dir, experiment, fuzzer_id, crash_id):
  pattern = os.path.join(base_dir, triage_dir, experiment, "fuzzer%02d" % (fuzzer_id + 1), "crashes", "id:%06d*" % (crash_id)) 
  file_list = glob.glob(pattern) 
  #TODO : if file list is empty or has more than one
  print "%s %d %d" % (str(file_list) , fuzzer_id, crash_id)
  with open(file_list[0],"r") as f:
    return f.read().strip()

def getPlotData(base_dir, experiment):
  # grab the 8 plot data
  plot_data = []
  for i in xrange(8):
    plot_data.append( getData(os.path.join(base_dir, experiment, "fuzzer0" + str(i + 1),"plot_data")) )

  # Initialize the buffers
  time_queue = PriorityQueue()
  lengths=[]
  last_crash_id=[]
  last_execs=[]
  start_time = plot_data[0][0][0]
  for i in xrange(8):
    time_queue.put( (plot_data[i][0][0], i, 0) )
    lengths.append(len(plot_data[i]))
    last_crash_id.append(0)
    last_execs.append(0)
    # it is expected that the first data point of a plot_data is the earliest data point. Otherwise there is a need for sorting.
    if (plot_data[i][0][0] < start_time):
      start_time = plot_data[i][0][0]

  execs_data=[]
  crash_data=[]
  execs_data.append(0)
  crash_data.append(0)
  current_crashes = 0
  last_time = 0
  bug_stats = []
#  bug_stats.append("bug_id,execs_first_found\n")
  bug_stats.append("bug_id,time_first_found\n")
  # go through the data points in a first come first serve basis. The reference (start_time) is the earliest data point.
  while not time_queue.empty():
    current_time, current_id, row_index = time_queue.get()
    last_time = current_time
    if current_time - start_time > time_cap:
      print "exceeded time cap %d %d (%d > %d)" % (current_time, start_time, current_time - start_time, time_cap)
      break
    last_execs[current_id] = plot_data[current_id][row_index][2]
    total_execs = sum(last_execs)

    # if new bug is found
    if plot_data[current_id][row_index][1] > last_crash_id[current_id]:
      for i in xrange(last_crash_id[current_id], plot_data[current_id][row_index][1]):
        sh = get_stack_hash(base_dir, experiment, current_id, i)
        if len(sh) > 0 and  sh not in stack_hashes:
          stack_hashes.add(sh)
          current_crashes += 1
          # print the crash ID and exec (now it is switched to time)
#          bug_stats.append("%s,%d\n" % (sh, total_execs))
          bug_stats.append("%s,%d\n" % (sh, current_time - start_time))
          
      last_crash_id[current_id] = plot_data[current_id][row_index][1]
    
    execs_data.append(total_execs)
    crash_data.append(current_crashes)

    if row_index + 1 < lengths[current_id]:
      time_queue.put( (plot_data[current_id][row_index + 1][0], current_id, row_index + 1) )

  execs_data.append(sum(last_execs))
  crash_data.append(current_crashes)
  return (execs_data, crash_data, bug_stats)

execs_data, crash_data, bug_stats = getPlotData(base_dir, experiment)
with open(out_file, "w") as f:
  length = len(execs_data)
  f.write("Iteration,num_crashes\n")
  for i in xrange(length):
    f.write("%d,%d\n" % (execs_data[i], crash_data[i]))

with open(bug_stats_file, "w") as f:
  length = len (bug_stats)
  for i in xrange(length):
    f.write(bug_stats[i])
