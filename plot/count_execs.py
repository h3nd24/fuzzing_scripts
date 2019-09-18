import os
import shutil
import argparse
import glob
import time
import sys
import csv 

# TAGS: seed_stats

def getData(file_name):
        fuzzer_info = []
        with open(file_name[0], 'rb') as csvfile:
                reader = csv.DictReader(csvfile, skipinitialspace=True)
                for row in reader:
                        fuzzer_info.append( [ int(row['cur_path']), int(row['paths_total']), int(row['total_execs'])  ] )
        return fuzzer_info

parser = argparse.ArgumentParser( description="Trace AFL crashes back to their sources and gather the statistics, e.g., the executions allocated to each seed. It will be processed further by \"count_execs_avg.py\" and \"plot_seed_stats_grouped.R\"")
parser.add_argument('dir', metavar='Dir', type=str, nargs=1, help='Fuzzing run directory, e.g., \"cmin_1\"')
parser.add_argument('-o', '--output', help="output file name, which will be consumed by \"count_execs_avg.py\"")
args = parser.parse_args()
print args

base_dir = args.dir[0]
output_file = args.output

execs = {}
paths = {}

def search_file(file_name, pattern):
# TODO : room for improvement: use binary search
  with open(file_name, "read") as f:
    for line in f:
      if pattern in line:
#        print line
        return line

  print "can't find %s in %s" % (pattern, file_name)
  exit(1)
   

def trace_source(entry, add_execs, add_paths):
	if entry.orig:
		orig = entry.orig
		if orig not in execs:
			execs[orig] = add_execs
		else:
			execs[orig] += add_execs
		if orig not in paths:
			paths[orig] = add_paths
		else:
			paths[orig] += add_paths
	for (f, p) in entry.parents:
		parent = Entry.parse_by_queue_id(p, f)
		trace_source(parent, add_execs, add_paths)

# a class to represent the long version of fuzzing entries:
#   id:XX,[ sig:XX, ][ [sync:XX,]src:XX, | orig:XX, ]<dont_care>
#   
class Entry:
#	def __init__ (fuzzer_id, current_id, signal, parents, orig):
	def __init__ (self, parents, orig):
#		_fuzzer_id = fuzzer_id
#		_signal = signal
#		_current_id = current_id
		self.parents = parents
		self.orig = orig

	@staticmethod
	def parse(file_name, fuzzer_dir):
		#TODO
		# if it is synced from other fuzzers
		idx = file_name.find("sync")
		parent_fuzzer_dir = fuzzer_dir
		parents = []
#		current_id = "000000"
		orig = ""
		if idx != -1:
			idx += 5
			idx2 = file_name.find(",src", idx)
			if idx2 < 0:
				print "Error: can't find 'src' on a synced entry " + file_name
				exit(1)
			parent_fuzzer_dir = file_name[idx:idx2]
			parents.append( (parent_fuzzer_dir, file_name[idx2+5:idx2+11]) )
		else:
			# if it is generated on its own
			idx = file_name.find("src")
			if idx >= 0:
				idx += 4
				idx2 = file_name.find("+", idx, idx + 6)
				parents = []
				if idx2 != -1:
					parents.append( (parent_fuzzer_dir, \
						file_name[idx:idx2]) )
					parents.append( (parent_fuzzer_dir, \
						file_name[idx2+1:idx2+7]) )
#					print str(parents)
				else:
					parents.append( (parent_fuzzer_dir, \
						file_name[idx:idx+6]) )
			# if it is the source
			else:
				idx = file_name.find("orig")
				if idx != -1:
					orig = file_name[idx+5:]
#		return entry(fuzzer_id, current_id, signal, parents)
		return Entry(parents, orig)
              
#       entry_id is already of the form 000000
	@staticmethod
	def parse_by_queue_id(entry_id, fuzzer_dir):
#		file_name = glob.glob( os.path.join( \
#			base_dir, fuzzer_dir, "queue", "id:" + entry_id + "*") )
#		if len(file_name) == 1:
#			return Entry.parse(os.path.basename(file_name[0]), fuzzer_dir)
#		else:
#			if len(file_name) > 1:
#				print "duplicate entry id in the same fuzzer %s" % entry_id
#			else:
#				print "file not found %s" % entry_id
#			exit(1)

# Now it is changed to read a file list instead since there is not enough inodes in the workstation
                file_name = search_file(os.path.join(base_dir, fuzzer_dir, "queue", "file_list"), "id:%s" % entry_id)
                return Entry.parse(file_name, fuzzer_dir)

#stat = program_status(interval=0.5)
#stat.update_stat(False)

fuzzers = glob.glob( os.path.join(base_dir, "*") )
total_crashes = 0

# iterate over all crashes in all fuzzers
for fuzzer_dir in fuzzers:
	plot_data = glob.glob( os.path.join(fuzzer_dir, "plot_data") )
        if len(plot_data) == 0:
          print "can't find %s" % (os.path.join(fuzzer_dir, "plot_data"))
          sys.exit()
        data = getData(plot_data)
	N = len(data)
#	stat.add_module(fuzzer_dir)
#	stat.set_total(fuzzer_n, N)
        # main engine to traverse the plot_dataa
        last_id = 0
        last_execs = 0
        last_paths = 0
        if len(data) >= 1:
          last_paths = data[0][1]
        cur_id = 0
        cur_paths = 0
        cur_execs = 0
        data_len = len(data)
#        print fuzzer_dir
#        sys.stdout.write("id : 0\n")
        for i in xrange(data_len):
          cur_id = data[i][0]
          cur_paths = data[i][1]
          cur_execs = data[i][2]
          if cur_id != last_id:
#            sys.stdout.write("\033[1A\033[K")
#            sys.stdout.write("id : (%d %d %d) (%d %d %d)\n" % (cur_id, cur_execs, cur_paths, last_id, last_execs, last_paths) )

#            glob_exp = os.path.join(fuzzer_dir, "queue", "id:%06d*" % (last_id) ) 
#	    files = glob.glob( glob_exp  )
#            if len(files) == 0:
#              print "no file match %s" % glob_exp
#              sys.exit()
#            elif len(files) > 1:
#              print "more than 1 file match %s" % glob_exp
#              sys.exit()
#            current_entry = Entry.parse(os.path.basename(files[0]), os.path.basename(fuzzer_dir) )

            file_name = search_file(os.path.join(fuzzer_dir, "queue", "file_list"), "id:%06d" % (last_id))
            current_entry = Entry.parse(file_name, os.path.basename(fuzzer_dir))
            trace_source(current_entry, cur_execs - last_execs, cur_paths - last_paths)
            last_id = cur_id
            last_execs = cur_execs
            last_paths = cur_paths
          # the fuzzer is still fuzzing the last item
        if cur_execs > last_execs: 
#          sys.stdout.write("\033[1A\033[K")
#          sys.stdout.write("id : (%d %d %d) (%d %d %d)\n" % (cur_id, cur_execs, cur_paths, last_id, last_execs, last_paths) )
#          glob_exp = os.path.join(fuzzer_dir, "queue", "id:%06d*" % (last_id) ) 
#	  files = glob.glob( glob_exp  )
#          if len(files) == 0:
#            print "no file match %s" % glob_exp
#            sys.exit()
#          elif len(files) > 1:
#            print "more than 1 file match %s" % glob_exp
#            sys.exit()
#          current_entry = Entry.parse(os.path.basename(files[0]), os.path.basename(fuzzer_dir) )

          file_name = search_file(os.path.join(fuzzer_dir, "queue", "file_list"), "id:%06d" % (last_id))
          current_entry = Entry.parse(file_name, os.path.basename(fuzzer_dir))
          trace_source(current_entry, cur_execs - last_execs, cur_paths - last_paths)
		
# output 
with open(output_file, "w") as f:
	f.write("seed,execs,paths\n")
	for (key, value) in execs.iteritems():
		f.write( key.rstrip() + "," + str(value) + "," + str(paths[key]) + "\n" )
