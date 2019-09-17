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

import numpy as np

parser = argparse.ArgumentParser( \
	description="Calculate the PCA operators from the tuples (result of afl-showmap).")
parser.add_argument('-i', '--inputdir', default=".", type=str, help='Input directory, the result of afl-showmap.')
parser.add_argument('-o', '--output', default="data", help="Output file of the serialized learned PCA operators.")
parser.add_argument(      '--chunk-size', default=1000, help="Chunk size for the incremental PCA")
parser.add_argument(      '--prefix', default="afltuples", help="Prefix of the file to be included in the PCA calculation")
parser.add_argument(      '--pca-dimensions', default=2, help="Target dimension for PCA projection")
args = parser.parse_args()

cwd = os.getcwd()
base_dir = os.path.join(cwd, args.inputdir)
outfile = os.path.join(cwd, args.output)

all_files = []
filecount = 0
last_calculated = 0
sys.stdout.write("0\n")
last_time = time.time()
chunk_size = args.chunk_size
prefix = args.prefix
inc_pca = decomposition.IncrementalPCA(n_components=args.pca_dimensions)
# incrementally fit the PCA based on chunk_size
for dirpath, dirnames, filenames in os.walk(base_dir):
    for name in filenames:
        if name.startswith(prefix):
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

            # time to calculate the incremental PCA
            if filecount - last_calculated == chunk_size:
              if filecount - last_calculated > chunk_size:
                print ("weird things happening where it skipped files or something")
                exit(1)
              sys.stdout.write("\033[1A\033[K")
              sys.stdout.write("%d\n" % filecount)
              coverage = np.array(all_files)
              inc_pca.partial_fit(coverage)
              del all_files[:] # reset the matrix
              last_calculated = filecount

import pickle

# serialize the PCA object
with open(outfile, 'wb') as f:
  pickle.dump(inc_pca, f)

