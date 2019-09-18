import os
import shutil
import argparse
import glob
import time
import sys

# TAGS: trace_source

parser = argparse.ArgumentParser( description="trace AFL crashes back to their sources (Deprecated)")
parser.add_argument('dir', metavar='Dir', type=str, nargs=1, help='Fuzzing run directory, e.g., \"pdf_18h/cmin_1\"') 
parser.add_argument('-o', '--output', help="output file")
args = parser.parse_args()
print args
base_dir = args.dir[0]
output_file = args.output

significant_sources = {}

class program_status:
    
    def __init__(self, N=0, interval=1.0):
        self._N = N
        self._interval = interval
        self._last_show = time.time()
        self._start_timer = 0.0
        self._time = []
        self._item_N = []
        self._total_N = []
        self._label = []
        self._modules = 0
        self._last_modules = 0
        self._item_id = 0

    def add_module(self, module):
        self._time.append(0.0)
        self._item_N.append(0)
        self._total_N.append(self._N)
        self._label.append(module)
        self._modules += 1        

    def set_total(self, item_id, N):
        self._total_N[item_id] = N

    def start_timing(self):
        self.start_timer = time.time()

    def set_item_id(self, item_id):
        self._item_id = item_id

    def start_timing(self, item_id):
        self._start_timer = time.time()
        self._item_id = item_id

    def update_item(self,n):
        idx = self._item_id
        self._item_N[idx] = n
        cur_time = time.time()
        self._time[idx] += cur_time - self._start_timer
        if (cur_time - self._last_show >= self._interval):
            self._last_show = cur_time
            self.update_stat(True)

    def update_stat(self, revert_pos):
#        return
        if revert_pos:
            for i in xrange(self._last_modules):
                sys.stdout.write("\033[1A\033[K")
        self._last_modules = self._modules
        for i in xrange(self._modules):
            sys.stdout.write("%s: %.6fs\t%d/%d\t%.2f%%\n" % (self._label[i], self._time[i], self._item_N[i], self._total_N[i], (self._item_N[i] * 100.0 / float(self._total_N[i]))) )

def trace_source(entry):
	if entry.orig:
		orig = entry.orig
		if orig not in significant_sources:
			significant_sources[orig] = 1
		else:
			significant_sources[orig] += 1
	for (f, p) in entry.parents:
		parent = Entry.parse_by_queue_id(p, f)
		trace_source(parent)

# a class to represent the long version of fuzzing entries:
#   id:XX,[ sig:XX, ][ [sync:XX,]src:XX, | orig:XX, ]<dont_care>
#   
class Entry:
#	def __init__ (fuzzer_id, current_id, signal, parents, orig):
	def __init__ (self, parents, orig):
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
					print str(parents)
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
              
	@staticmethod
	def parse_by_queue_id(entry_id, fuzzer_dir):
		file_name = glob.glob( os.path.join( \
			base_dir, fuzzer_dir, "queue", "id:" + entry_id + "*") )
		if len(file_name) == 1:
			return Entry.parse(os.path.basename(file_name[0]), fuzzer_dir)
		else:
			if len(file_name) > 1:
				print "duplicate entry id in the same fuzzer %s" % entry_id
			else:
				print "file not found %s" % entry_id
			exit(1)

#stat = program_status(interval=0.5)
#stat.update_stat(False)

fuzzers = glob.glob( os.path.join(base_dir, "*") )
total_crashes = 0

# iterate over all crashes in all fuzzers
fuzzer_n = 0
for fuzzer_dir in fuzzers:
	crashes = glob.glob( os.path.join(fuzzer_dir, "crashes_to_trace", "id*") )
        print crashes
	N = len(crashes)
#	stat.add_module(fuzzer_dir)
#	stat.set_total(fuzzer_n, N)
	f_counter = 0
	total_crashes += N
	for f in crashes:
		f_counter += 1
#		stat.start_timing(fuzzer_n)
		# parse relevant information then trace its sources
		current_entry = Entry.parse(os.path.basename(f), \
			os.path.basename(fuzzer_dir) )
		trace_source(current_entry)
#		stat.update_item(f_counter)
	fuzzer_n += 1
		
# output 
with open(output_file, "w") as f:
	for (key, value) in significant_sources.iteritems():
		f.write( key + " " + str(value) + " " + str(total_crashes) + "\n" )
