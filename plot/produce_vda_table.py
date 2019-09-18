
import csv
import argparse
import sys 

parser = argparse.ArgumentParser( description="Produce vda values for result table in the paper")
parser.add_argument('-i', '--input', type=str, help='result file')
parser.add_argument(      '--base', help="reference point for the VDA")
parser.add_argument(      '--target', help="target program (for cosmetic purpose)")
parser.add_argument(      '--algs', default="moonshine moonshine_size moonshine_time empty full", help="Corpus distillation technique to compare against the reference point")
args = parser.parse_args()

inputfile = args.input
target = args.target
base = args.base
algs = args.algs.split(" ")
magnitude_map = {
  "negligible" : 1,
  "small" : 2,
  "medium" : 3,
  "large" : 4
}
#magnitude_translate = lambda magnitude: magnitude_map[magnitude]
winner_table = {} 
winner_table_AUC = {}
loser_table = {}
loser_table_AUC = {}
with open(inputfile, "rb") as csvfile:
  reader = csv.DictReader(csvfile,skipinitialspace=True)
  for row in reader:
    value_type = row['value_type']
    winner = row['winner']
    loser = row['loser']
    magnitude = row['magnitude'] 

    if winner == base:
      if value_type == "crashes":
        winner_table[loser] = magnitude_map[magnitude]
      elif value_type == "AUC":
        winner_table_AUC[loser] = magnitude_map[magnitude]
    elif loser == base:
      if value_type == "crashes":
        loser_table[winner] = magnitude_map[magnitude]
      elif value_type == "AUC":
        loser_table_AUC[winner] = magnitude_map[magnitude]

sys.stdout.write("%s" % target)
for alg in algs:
  sys.stdout.write(" & ")
  if alg in winner_table:
    for i in xrange(winner_table[alg]):
      sys.stdout.write("-")
  elif alg in loser_table:
    for i in xrange(loser_table[alg]):
      sys.stdout.write("+")
  else:
      sys.stdout.write("0")
#  sys.stdout.write(" & ")
#  if alg in winner_table_AUC:
#    for i in xrange(winner_table_AUC[alg]):
#      sys.stdout.write("-")
#  elif alg in loser_table_AUC:
#    for i in xrange(loser_table_AUC[alg]):
#      sys.stdout.write("+")
#  else:
#      sys.stdout.write("0")

sys.stdout.write(" \\\\\n")
