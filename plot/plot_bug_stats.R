#!/usr/bin/Rscript
#!/usr/bin/env Rscript 

# This is the main interface for the script to plot the seed statistics.
# The data will be of the form <inputprefix>_<alg>_<n> where 1 <= n <= 30 and <alg> in <algnames>, and the data is taken from the output of time_to_find.py
 
library(optparse)
library(ggplot2)
source(file="plot_utils.R")
source(file="plot_bug_function.R")
option_list <- list(
  make_option("--inputdir", default=".", help="Directory containing the plot data"),
  make_option("--algnames", default="cmin moonshine_size minset moonshine_size_rs empty", help="Distillation techniques"),
#  make_option("--xmax", default=28793041, help="Maximum execution, this may need to be supplied from outside"),
  make_option("--inputprefix", default="sox_18h_bug_stats", help="input file prefix"),
  make_option("--output", default="plot_1.pdf", help="output file name"),
  make_option("--maxtrials", default=30, type="integer", help="number of experiments / trials"),
  make_option("--bugs", default="A B C D E F G H", help="bugs associated with this program"),
  make_option("--title", default="Number of Executions to Expose Bugs (SoX - MP3)", help="Plot main title"),
  make_option("--numbuckets", default=10, type="integer", help="Number of bucketed speed (Not used anymore)")
)
opt <- parse_args(OptionParser(option_list=option_list))
algnames <- unlist (strsplit(opt$algnames, " ") )
bugs <- unlist (strsplit(opt$bugs, " "))
cat(str( opt))
iname = opt$output
inputdir = opt$inputdir
inputprefix = opt$inputprefix
maxtrials = as.numeric(opt$maxtrials)
numbuckets = as.numeric(opt$numbuckets)
#xmax = opt$xmax
title = opt$title

mod_summary = function(data) {
  sub_data = subset(data, data > 0)
  y = 0
  ymin = 0
  ymax = 0
  if (length(sub_data) > 0) { 
    y = mean(sub_data) 
    ymin = min(sub_data)
    ymax = max(sub_data)
  }
  return (data.frame(ymin = ymin,
        ymax = ymax,
        y = y
      )
    )
}

div1M = function(data) {
  return ( round(data / 1000000,0) )
}

translate_name = function(alg) { return (possible_names[[alg]]) }

{
  combined_df = data.frame( Alg=character(),
    BugID=character(),
    Execs=integer() )
  count_non_bug = list()
  for (alg in algnames) {
    for (bug in bugs) {
      count_non_bug[[alg]][[bug]] = 0L
    }
  }
  for (idx in 1:length(algnames)) {
    alg <- algnames[idx]
    for (i in 1:maxtrials) {
      fname <- paste(inputprefix, alg, i, sep="_")
      DATA = grabData(inputdir, fname)
      if (length(DATA[["time_first_found"]]) > 0) {
#        cat("LENGTH > 0", "\n")
        for ( bug in bugs ) {
          if (!bug %in% DATA$bug_id) { 
            levels(DATA$bug_id) = c(levels(DATA$bug_id), bug) 
            DATA = rbind(DATA, c(bug, 0L)) 
            count_non_bug[[alg]][[bug]] = count_non_bug[[alg]][[bug]] + 1L
          }
        }
      }
      else { # if the length is 0. It is inconceivable that the length should be negative
        DATA = data.frame(bug_id = factor(), time_first_found = integer())
        levels(DATA$bug_id) = bugs
        for (bug in bugs ) {
          row = c(bug_id = bug, time_first_found = 0L )
          DATA[length(DATA$bug_id)+1,] = row
          count_non_bug[[alg]][[bug]] = count_non_bug[[alg]][[bug]] + 1L
        }
      }
      combined_df = rbind(combined_df, cbind(Alg=possible_names[[alg]], DATA ) )
    }
  }
#  str(combined_df)
#  max_execs = max(as.numeric(combined_df[["execs_first_found"]]), na.rm=T)
#  cat (str(max_execs))

#  This will be needed for plotting_1
#  max_execs = xmax
#  execs_boundary = max_execs %/% numbuckets + 1
#  hist_breaks = c(seq(0, max_execs, execs_boundary), max_execs + 1)
  
#  combined_df = subset(combined_df, bug_id == bug)

  #str(combined_df)
  df_labels = data.frame ( Alg=character(),
    bug_id=character(),
    count=integer() )
  actual_names = sapply(algnames, translate_name)
  levels(df_labels$Alg) = actual_names
  levels(df_labels$bug_id) = bugs
  for (alg in algnames) {
    for (bug in bugs) {
      df_labels[nrow(df_labels) + 1,] = c(Alg=possible_names[[alg]], bug_id=bug, count=30 - count_non_bug[[alg]][[bug]] ) 
    }
  }
#  combined_df$execs_first_found = as.numeric(combined_df$execs_first_found)
#  str(combined_df$execs_first_found) 
#  str(df_labels)

#  plotting_1(combined_df, hist_breaks)
  plotting_7(combined_df, algnames, possible_names, bugs, iname)
#  ggsave(iname, plot=p, device="pdf")
#  warnings()
}
#warnings()
