import csv
import os
import shutil
import glob
import argparse
from Queue import PriorityQueue

# TAGS: bugs_over_time

parser = argparse.ArgumentParser( \
	description="Transform CSV of bug IDs to file (to be processed further by \"time_to_find.py\"). The output files are of the form \"id:X\" where X is six-digits zero-padded ID corresponding to the crashes IDs.")
parser.add_argument('-i', '--input', type=str, help='input CSV file')
parser.add_argument('-o', '--output', type=str, help='base output directory, e.g., \"fuzz_data/sox_18h/triage_output\"')
args = parser.parse_args()

def csv_to_file(file_name, out_dir):
  with open(file_name, 'rb') as csvfile:
    reader = csv.DictReader(csvfile, skipinitialspace=True)
    for row in reader:
      experiment = "%s_%d" % (row['experiment_type'], int(row['trial_number']) )
      fuzzer_id = "fuzzer%02d" % (int(row['fuzzer_id']))
      crash_id = int(row['crash_id'])
      bug_id = row['bug_id']

      experiment_dir = os.path.join(out_dir, experiment)
      fuzzer_dir = os.path.join(experiment_dir, fuzzer_id)
      crash_dir = os.path.join(fuzzer_dir, "crashes")
      out_file = os.path.join(crash_dir, "id:%06d" % crash_id)

      # create directories if not exist
      if not os.path.exists( experiment_dir ):
        os.mkdir( experiment_dir )

      if not os.path.exists( fuzzer_dir ):
        os.mkdir( fuzzer_dir )
        os.mkdir( crash_dir )

      # create the crash file with the bug ID as its content
      with open(out_file, 'w') as f:
        f.write(bug_id)      


cwd = os.getcwd()
in_file = os.path.join(cwd, args.input)
out_dir = os.path.join(cwd, args.output)

print args

if not os.path.exists( out_dir ):
  os.mkdir( out_dir )
csv_to_file(in_file, out_dir)
