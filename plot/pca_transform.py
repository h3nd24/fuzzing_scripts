#!/usr/bin/env python

from __future__ import print_function
import time
import sys
import argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import os
from sklearn import decomposition
import pickle
import numpy as np

parser = argparse.ArgumentParser( \
	description="Transform tuples into lower dimension using the pca operator calculated by pca.py. Applied to the tuples of various distillation techniques contained in \"<inputprefix>_<alg>_<inputpostfix>\" where <alg> is a distillation technique.")
parser.add_argument(      '--inputprefix', default="sox", type=str, help='Prefix for corpus directories')
parser.add_argument(      '--inputpostfix', default="tuples", type=str, help='Postfix for corpus directories')
parser.add_argument(      '--algs', default="full cmin moonshine moonshine_size moonshine_time minset", type=str, help="Corpus distillation techniques")
parser.add_argument(      '--pca-operators', default="pca_operators_all.pkl", help="Serialized file of PCA operators (output of pca.py)")
parser.add_argument('-o', '--output', default="sox_corpus_distance.pdf", help="output file")
parser.add_argument(      '--outputprefix', default="sox_corpus_distance", help="prefix for intermediate output data for further processing by plot_corpus_distance.R")
args = parser.parse_args()
print(args)
cwd = os.getcwd()
outfile = os.path.join(cwd, args.output)
pca_file = os.path.join(cwd, args.pca_operators)
inputprefix = args.inputprefix
inputpostfix = args.inputpostfix
outputprefix = args.outputprefix
algs = args.algs.split(" ")
# serialize the PCA object
with open(pca_file, 'rb') as inputfile:
  inc_pca = pickle.load(inputfile)


last_time = time.time()
item_idx = 0
line_handles = []
line_labels = []
chunk_size = 1000
for alg in algs:
    base_dir = os.path.join(cwd, "%s_%s_%s" % (inputprefix, alg, inputpostfix))
    intermediate_file = os.path.join(cwd, "%s_%s" % (outputprefix, alg))
    with open(intermediate_file, "w") as f:
      f.write("X,Y\n")
    filecount = 0
    all_files = []
    names = []
    sys.stdout.write("0\n")
    last_calculated = 0
    for dirpath, dirnames, filenames in os.walk(base_dir):
        for name in filenames:
          names.append(name)
          filecount = filecount + 1
          data = {}
          with open(os.path.join(dirpath, name)) as f:
              for line in f:
                  index, count = line.split(':')
                  data[int(index)] = int(count)
  
          ldata = []
          for i in xrange(0, 65536):
              ldata.append(data.get(i, 0))
  
          all_files.append(ldata)
          current_time = time.time()
          if current_time - last_time > 1:
            sys.stdout.write("\033[1A\033[K")
            sys.stdout.write("%d\n" % filecount)
            last_time = current_time

          if filecount - last_calculated == chunk_size:
              if filecount - last_calculated > chunk_size:
                  print ("weird things happening where it skipped files or something")
                  exit(1)
              sys.stdout.write("\033[1A\033[K")
              sys.stdout.write("%d\n" % filecount)
              coverage = np.array(all_files)
              transformed = inc_pca.transform(coverage)
              with open(intermediate_file, "a") as f:
                for p in transformed:
                  f.write("%f,%f\n" % (p[0], p[1]))
              del all_files[:] # reset the matrix
              del names[:]
              last_calculated = filecount

    sys.stdout.write("\033[1A\033[K")
    sys.stdout.write("%d\n" % filecount)
    coverage = np.array(all_files)
    transformed = inc_pca.transform(coverage)
    with open(intermediate_file, "a") as f:
      for p in transformed:
        f.write("%f,%f\n" % (p[0], p[1]))
    transformed_len = len(transformed)
    for i in xrange(len(names)):
      sys.stdout.write("%s" % (names[i]))
      if (i < transformed_len):
        sys.stdout.write("%s" % (transformed[i]))
      sys.stdout.write("\n") 
    item_idx += 1

