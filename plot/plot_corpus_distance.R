#!/usr/bin/Rscript
#!/usr/bin/env Rscript 
library(boot)
source(file="plot_utils.R")

# TAGS: corpus_distance
# Plot the corpus distance, takes the data points from the result of pca_transform.py

option_list <- list(
  make_option("--inputdir", default=".", help="Directory containing the plot data, default to \".\""),
  make_option("--algnames", default="full minset moonshine_size", help="Distillation techniques"),
  make_option("--inputprefix", default="sox_corpus_distance", help="Input file prefix, default to \"sox_corpus_distance\""),
  make_option("--output", default="sox_corpus_distance.pdf", help="Output file name, default to \"sox_corpus_distance.pdf\""),
  make_option("--title", default="SoX (MP3) - Corpus Distance", help="Title for the plot")
)
opt <- parse_args(OptionParser(option_list=option_list))
algnames <- unlist (strsplit(opt$algnames, " ") )
#target <- opt$target
#time_limit = paste0(opt$timelimit,"h")
cat(str( opt))
inputprefix = opt$inputprefix
iname = opt$output
inputdir = opt$inputdir
title = opt$title
index = list()
index[["full"]] = 1
index[["afl-cmin"]] = 2
index[["minset"]] = 3
index[["moonshine"]] = 7
index[["moonshine_size"]] = 4 
index[["moonshine_time"]] = 8
index[["greedy"]] = 9
index[["empty"]] = 5
index[["random"]] = 6

for (i in 1:length(algnames)) {
  if (algnames[i] %in% names(possible_names)) {
    actual_names[[i]] <- possible_names[[algnames[i]]]
  } else { actual_names[[i]] <- algnames[i] }
#  cat (paste(i,actual_names[[i]], algnames[i], possible_names[[algnames[i]]], sep=" "))
}

{
  X <- list()
  Y <- list()
  value_list <- list()
  # ingest all the data
 
#  outprefix = "Coverage-avg"
#  iname <- paste0(outprefix,"-", target,"-",time_limit,".pdf")
  xmax = 0
  ymax = 0
  ymin = .Machine$integer.max
  xmin = .Machine$integer.max 
  for (idx in 1:length(algnames)) {
      alg <- algnames[idx]
      
      # raw average
      # Get the data in the right format
      fname <- paste(inputprefix, alg, sep="_")
      DATA = grabData(inputdir, fname)
      X[[alg]] <- DATA["X"]
      Y[[alg]] <- DATA["Y"]

      # Number of samples
      samples = length(DATA["X"][,])
      # find max Y
      max_y = max(DATA["Y"])
      if (max_y > ymax) { ymax <- max_y }
      min_y = min(DATA["Y"])
      if (min_y < ymin) { ymin <- min_y }
      # find max X
      max_x = max(DATA["X"])
      if (max_x > xmax) { xmax <- max_x }
      min_x = min(DATA["X"])
      if (min_x < xmin) { xmin <- min_x }
      
  }
 
  # now plot all the trial data
#  cat("Preparing to plot...\n")
  num_tables = 0
  figParam = GetFigParams(num_tables, 700)
  cat(figlongwidth, figheight, "\n")
  pdf(iname,width=figParam$width/72.0,height=figParam$height/72.0)
  value_dev <- dev.cur()
  SetLayout(num_tables)

  PlotMain(cur_dev=value_dev, xmin=xmin, xmax=xmax, xdiv=(xmax - xmin) / 10.0, 
    ymin=ymin, ymax=ymax, ydiv=(ymax - ymin) / 10.0, main_lab=title, 
    xlab="", ylab="", 
    xaxis_offset=figParam$xaxis_offset, yaxis_offset=figParam$yaxis_offset)

  used_colors = c()
  used_symbols = c()
  for (idx in 1:length(algnames)) {
    alg = algnames[idx]
    X1 <- X[[alg]]
    Y1 <- Y[[alg]]
    colour = colours[index[[alg]] ]
    line_type = lntypes[index[[alg]] ]
    symbol = symbols[index[[alg]] ]
    dev.set(value_dev)
    points(X1[,1], # X
           Y1[,1], # Y
           type='p', col = colour, lwd = 5, pch=symbol)
    used_colors = c(used_colors, colour)
    used_symbols = c(used_symbols, symbol)
    }
  PlotLegend("bottomright", 0.05, used_colors, used_symbols)
  
  dev.off(value_dev)
  cat ("finishing\n")

}

