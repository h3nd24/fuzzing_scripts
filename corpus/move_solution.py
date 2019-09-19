import shutil
import os
import re
import json
import argparse

# TAGS: move_solution

REGEX = re.compile(r'exemplar_(?P<name>.*)\.bv$')

parser = argparse.ArgumentParser(description='Copy the files in the solution (JSON format) to a destination folder. The list of files is the \"solution\" element of the JSON.')
parser.add_argument('-i', '--in-dir', default=".",
                                help='Directory containing the the input files')
parser.add_argument('-s', '--solution', help='Name of the solution file')
parser.add_argument('-o', '--out-dir', help='Output directory')
parser.add_argument(      '--input-prefix', default="afltuples-", \
  help="Prefix to the input files if needed, e.g., \"afltuples-\" for the AFL tuples files")
parser.add_argument(      '--output-prefix', default="afltuples-", help="Prefix of the output (copied) files")
args = parser.parse_args()
print args

input_prefix = args.input_prefix
output_prefix = args.output_prefix
source_dir = args.in_dir
solution = args.solution
out_dir = args.out_dir

def func(source_dir, solution, outdir, input_prefix, output_prefix):
  if not os.path.isdir(outdir):
      os.makedirs(outdir)
  with open(solution, "r") as f:
    data = json.load(f)
  for i in data["solution"]:
    print(i)
    orig_name = REGEX.search(i).group("name")
    shutil.copy2("%s/%s%s" % (source_dir, input_prefix, orig_name), "%s/%s%s" % (outdir, output_prefix, orig_name))

func(source_dir, solution, out_dir, input_prefix, output_prefix)
