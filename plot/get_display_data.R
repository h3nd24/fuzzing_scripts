#!/usr/bin/Rscript
#!/usr/bin/env Rscript 

# TAGS: bugs_over_time, coverage_over_time

#library(methods)
#library(stringr)
library(optparse)
#library(grid)
#library(vcd)
#library(gridExtra)
#library(gridBase)
#library(gtable)

# Script to cut down the number of data points to plot, works by removing the "overlapping" points to small resolution

option_list <- list(
  make_option("--inputdir", default=".", help="Directory containing the plot data, e.g., \"dedup_plot_data\""),
  make_option("--outputdir", default="plot_data_stats", help="Directory containing the plot data, default to \"plot_data_stats\""),
  make_option("--inputprefix", default="plot_data", help="input file prefix, e.g., \"pdf_18h_bug_crashes\""),
  make_option("--inputpostfix", default="execs_avg", help="input file postfix, default to \"avg\""),
  make_option("--algnames", default="cmin", help="corpus treatment, e.g., \"cmin\""),
  make_option("--maxtrials", default="30", type="character", help="max experiments for each corpus treatment, default to 30"),
  make_option("--outputprefix", help="outfile prefix, e.g., \"pdf_18h_bug_crashes\" "),
  make_option("--outputpostfix", default="display_data", help="outfile postfix, default to \"display_data\""),
  make_option("--fieldname", default="map_size", help="field of interest apart from 'Iteration', output from previous script has possible field name of 'num_crashes' or 'map_size'")
)

opt <- parse_args(OptionParser(option_list=option_list))
algnames <- unlist (strsplit(opt$algnames, " ") )
cat(str( opt))
max_experiment = unlist (strsplit(opt$maxtrials, " ") )
datastore = opt$inputdir
outputdir = opt$outputdir
prefix = opt$inputprefix
inputpostfix = opt$inputpostfix
outpostfix = opt$outputpostfix
outprefix = opt$outputprefix
fieldname = opt$fieldname

# Get the data from the CSV file
grabData = function(datastore, filename) {
  fname <- paste(datastore,filename,sep="/")
  DATA <- read.table(fname,sep=",",header=TRUE)
  return (DATA)
}

{
  maxtrials = 0
  VALUE <- list()
  EXECS <- list()
  # grab the values for xmax and xdiv
  for (idx in 1:length(algnames)) {
    alg <- algnames[idx]
    cat(alg,"\n")
    # Get the data in the right format
    fname <- paste(prefix,alg,inputpostfix, sep="_")
    #cat("file name: ", fname, "\n")
    DATA = grabData(datastore,fname)
    EXECS[[alg]] <- DATA["Iteration"]
    VALUE[[alg]] <- DATA[fieldname]
    
    # find max X
    duration = max(DATA["Iteration"])
    if (duration > maxtrials) {
      maxtrials <- duration
    }
  }
  # adjust scales
  xdiv = 1e6
  if (maxtrials > 5e8) { xdiv = 1e8 } else if (maxtrials > 5e7) { xdiv = 1e7 }
  cat ("Maxtrials: ", maxtrials, " xdiv: ", xdiv, "\n")
  interval = xdiv %/% 50 # the smallest resolution
  for (idx in 1:length(algnames)) {
    alg <- algnames[idx]
    fname = paste(outputdir, paste(outprefix,alg,outpostfix, sep="_"), sep="/")
    cat(paste0("Iteration,",fieldname,"\n"), file=fname)
    # for now assume that it will never modulo 0
    X1 <- list()
    Y1 <- list()
    X1_all <- EXECS[[alg]]$Iteration
    Y1_all <- VALUE[[alg]][,1]

    counter = 1
    last_added = 0
    len_X = length(X1_all)
    # only add the point that appeared after the smallest resolution
    for (j in 1:len_X) {
      bucket = X1_all[j] %/% interval
      if (X1_all[j] > last_added) {
        last_added = bucket * interval + interval
        X1[[counter]] = X1_all[j]
        Y1[[counter]] = Y1_all[j]
        counter = counter + 1
      }
    }
    # add the last point unconditionally
    X1[[counter]] = X1_all[len_X]
    Y1[[counter]] = Y1_all[len_X]

    # write the contents
    cat(paste(0, 0, sep=","), file=fname, append=T)
    cat("\n", file=fname, append=T)
    for (i in 1:counter) {
      cat(paste(X1[i], Y1[[i]], sep=","), file=fname, append=T, sep="")
      cat("\n", file=fname, append=T)
    }
  }
}

