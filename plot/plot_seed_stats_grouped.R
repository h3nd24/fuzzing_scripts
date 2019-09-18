#!/usr/bin/Rscript
#!/usr/bin/env Rscript 

# TAGS: seed_stats
# Script to plot the seed statistics (executions allocated) per distillation technique. 
# The seeds are sorted by the number of executions allocated.
library(optparse)
library(ggplot2)

option_list <- list(
  make_option("--input", default="seed_stats/sox_moonshine_size_avg.csv", help="input file which are the output of \"count_execs_avg.py\", e.g., \"seed_stats/sox_moonshine_size_avg.csv\""),
  make_option("--outputprefix", default="sox_moonshine_size_seed_stats", help="prefix for the output file name"),
  make_option("--title", default="SoX (MP3) Seed Statistics - MoonLight-S", help="Plot main title"),
  make_option("--highlight", default="", help="File which contains the seed(s) to highlight"),
  make_option("--limit", default=50, help="Number of seed to display, default to 50")
)
opt <- parse_args(OptionParser(option_list=option_list))
cat(str( opt))
input = opt$input
outputprefix = opt$outputprefix
outputexecs = paste(outputprefix,"execs.pdf", sep="_")
outputpaths = paste(outputprefix,"paths.pdf", sep="_")

highlight = c()
if (opt$highlight != "") {
  f = file(opt$highlight, "r")
  highlight_list = list()
  while ( TRUE ) {
    line = readLines(f, n = 1)
    if ( length(line) == 0 ) {
      break
    }
    highlight_list = append(highlight_list, line)
    str(line)
  }
  highlight = unlist( highlight_list )
}

str(highlight)

limitseed = opt$limit
title = opt$title
grabData = function(datastore,filename) {
  fname <- paste(datastore,filename,sep="/")
  DATA <- read.table(fname,sep=",",header=TRUE)
  return (DATA)
}

div1M = function(data) {
  return ( round(data / 1000000,2) )
}

identity_function = function(data) { return (data) }

plot_extras = function(base_plot, ylab, y_tick_function, title) {
  return (base_plot +
         geom_col(stat="identity", position="dodge") +
         geom_errorbar(aes(ymin=execs-sd_execs, ymax=execs+sd_execs), width=.2, position=position_dodge(.9)) +
         labs(title=title) + 
         xlab("Seed") + 
         scale_y_continuous(name="Average number of executions (x1M)", labels=y_tick_function, limit=c(-750000,55000000)) + 
         scale_fill_manual( values = c( "yes"="tomato", "no"="gray" ), guide = FALSE ) +
         theme (panel.grid.major = element_line(size = 0.5, linetype = 'dotted', color='grey'), panel.grid.minor = element_line(size = 0.5, linetype = 'dotted', color='grey')) +
         theme (panel.background = element_rect(fill = "white", colour = "white")) +
         theme (axis.line = element_line(size = 0.5, linetype = 'solid', color='black')) + 
         theme(axis.title.x = element_text(size=18), axis.title.y = element_text(size=18)) + 
         theme(axis.text.y = element_text(size=18)) + 
         theme(legend.title=element_blank(), axis.text.x = element_blank())
  )
}

{
  combined_df = data.frame( 
    seed=character(),
    execs=integer(),
    paths=integer() )
  DATA = grabData(".", input)
  combined_df = rbind(combined_df, DATA )
  sorted_df = combined_df[order(-combined_df$execs),]
  combined_df$seed = factor(combined_df$seed, levels = sorted_df$seed )
  combined_df = combined_df[order(-combined_df$execs),]
  combined_df = transform(combined_df, ToHighlight = ifelse(seed %in% highlight, "yes", "no"))
  if (length(combined_df$seed) >= limitseed) {combined_df = combined_df[1:limitseed,]}
  str(combined_df)
  # plot for execs
  p <- ggplot(combined_df, aes(x=seed, y=execs, fill=ToHighlight)) 
  p <- plot_extras(p, "Average number of executions (x1M)", div1M, title) 
  ggsave(outputexecs, plot=p, device="pdf")

  # plot for paths
  q <- ggplot(combined_df, aes(x=seed, y=paths, fill=ToHighlight)) 
  q <- plot_extras(q, "Number of seeds found", identity_function, title)
  ggsave(outputpaths, plot=q, device="pdf")
}


