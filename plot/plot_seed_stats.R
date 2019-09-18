#!/usr/bin/Rscript
#!/usr/bin/env Rscript 

# Script to plot the aggregate seed statistics acrosss the distillation techniques.
# This script is deprecated in favor of plot_seed_stats_grouped.R which shows individual seed statistics.
# Takes the output of "count_execs_avg.py" as input.
library(optparse)
library(ggplot2)

possible_names = list() # expansions on possible categories in the plot. This is currently hard coded
possible_names[["cmin"]] <- "afl-cmin"
possible_names[["moonshine"]] <- "MoonLight-U"
possible_names[["moonshine_size"]] <- "MoonLight-S"
possible_names[["moonshine_time"]] <- "MoonLight-T"
possible_names[["empty"]] <- "Empty"
possible_names[["full"]] <- "Full"
possible_names[["minset"]] <- "Unweighted Minset"
possible_names[["greedy"]] <- "MoonLight-G"

option_list <- list(
  make_option("--inputdir", default="seed_stats", help="Directory containing the plot data"),
  make_option("--algnames", default="minset moonshine_size", help="corpus treatment"),
  make_option("--inputprefix", default="sox", help="input file prefix"),
  make_option("--inputpostfix", default="avg.csv", help="input file postfix"),
  make_option("--outputexecs", default="sox_seed_stats_execs.pdf", help="output file name for execution stats"),
  make_option("--highlight", default="0e59e12799a9e5d39c4d560a9b4be9c4.mp3 e09609160f908ac3325b94e0ff27d179.mp3 84af07508efb98082938f99cdac06c62.mp3 cb836eb61b8c7c15968896742622f221.mp3 904704daf1cf2fb7bfffb00e8ed7152f.mp3", help="Highlight certain seeds"),
  make_option("--title", default="SoX (MP3) Seed Statistics", help="Plot main title"),
  make_option("--ymin", default=-750000, help="Minimum value for y-axis so that we have consistent axes across plots, default to -750000"),
  make_option("--ymax", default=17500000, help="Maximum value for y-axis so that we have consistent axes across plots, default to 17500000")
)
opt <- parse_args(OptionParser(option_list=option_list))
algnames <- unlist (strsplit(opt$algnames, " ") )
cat(str( opt))
inputdir = opt$inputdir
inputprefix = opt$inputprefix
inputpostfix = opt$inputpostfix
outputexecs = opt$outputexecs
outputpaths = opt$outputpaths
ymin=as.numeric(opt$ymin)
ymax=as.numeric(opt$ymax)
title = opt$title
highlight = unlist( strsplit(opt$highlight, " ") )
grabData = function(datastore,filename) {
  fname <- paste(datastore,filename,sep="/")
  DATA <- read.table(fname,sep=",",header=TRUE)
  return (DATA)
}

div1M = function(data) {
  return ( round(data / 1000000,0) )
}

identity_function = function(data) { return (data) }

plot_extras = function(base_plot, ylab, y_tick_function, title) {
  return (base_plot +
         geom_col(stat="identity", position="dodge") +
         geom_errorbar(aes(ymin=execs-sd_execs, ymax=execs+sd_execs), width=.2, position=position_dodge(.9)) +
         labs(title=title) + 
         xlab("Seed") + 
         scale_y_continuous(name="Average number of executions (x1M)", labels=y_tick_function, limit=c(ymin,ymax)) + 
         scale_fill_manual(labels = c("minset_yes" = "Unweighted Minset (seeds of interest)", "minset_no" = "Unweighted Minset", "moonshine_size_no"="MoonLight-S", "moonshine_size_yes" = "MoonLight-S (seeds of interest)"),
           values = c( "minset_yes"="tomato", "minset_no"="red", "moonshine_size_yes"="mediumpurple1", "moonshine_size_no"="purple3" )) +
         theme (panel.grid.major = element_line(size = 0.5, linetype = 'dotted', color='grey'), panel.grid.minor = element_line(size = 0.5, linetype = 'dotted', color='grey')) +
         theme (panel.background = element_rect(fill = "white", colour = "white")) +
         theme (axis.line = element_line(size = 0.5, linetype = 'solid', color='black')) + 
         theme (axis.title.x = element_text(size=18), axis.title.y = element_text(size=18)) + 
         theme (legend.position = c(1,1), legend.justification = c(1,1), legend.title=element_blank() ) + labs("Legend") + 
         theme (axis.text.y = element_text(size=18)) + 
         theme (axis.text.x = element_blank())
  )
}

