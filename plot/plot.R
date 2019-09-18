#!/usr/bin/Rscript
#!/usr/bin/env Rscript 

# TAGS: bugs_over_time, coverage_over_time

library(boot)
source(file="plot_utils.R")

option_list <- list(
  make_option("--inputdir", default="plot_data_stats", help="Directory containing the plot data, default to \"plot_data_stats\""),
  make_option("--algnames", default="", help="corpus treatment, e.g., \"full cmin\""),
  make_option("--maxtrials", default="30", type="character", help="max experiments for each corpus treatment, default to 30"),
  make_option("--inputprefix", default="plot_data", help="input file prefix, e.g., \"pdf_18h_bug_crashes\""),
  make_option("--inputpostfix", default="display_data", help="input file postfix, default to  \"display_data\""),
  make_option("--statpostfix", default="AUC", help="postfix for stats data (value and AUC per experiment, default to \"AUC\""),
  make_option("--output", default="plot.pdf", help="output file name"),
  make_option("--fieldname", default="map_size", help="field of interest apart from 'Iteration', output from previous script has possible field name of 'num_crashes' or 'map_size'"),
  make_option("--ylab", default="Map Size (%)", help="label for y-axis"),
  make_option("--sublab", default="Coverage against Iterations", help="sub-label for the plot"),
  make_option("--title", default="Coverage Plot", help="Title for the plot, (currently it is not used)"),
  make_option("--legendinset", default="0.035", help="Legend inset"),
  make_option("--legendpos", default="topleft", help="Legend position"),
  make_option("--conclusion", default=F, help="Include conclusions in figures")
)
opt <- parse_args(OptionParser(option_list=option_list))
algnames <- unlist (strsplit(opt$algnames, " ") )
#target <- opt$target
max_experiment = unlist (strsplit(opt$maxtrials, " ") )
#time_limit = paste0(opt$timelimit,"h")
fieldname = opt$fieldname
cat(str( opt))
inputprefix = opt$inputprefix
inputpostfix = opt$inputpostfix
statpostfix = opt$statpostfix
iname = opt$output
inputdir = opt$inputdir
ylab = opt$ylab
sublab = opt$sublab
title = opt$title
legendpos = opt$legendpos
legendinset = as.numeric(opt$legendinset)
include_conclusion = opt$conclusion
# get the expanded names for the distillation techniques used in plot
for (i in 1:length(algnames)) {
  if (algnames[i] %in% names(possible_names)) {
    actual_names[[i]] <- possible_names[[algnames[i]]]
  } else { actual_names[[i]] <- algnames[i] }
}

{
  dedup_prefix = paste(target,time_limit,sep="_")
  cat("Processing Target: ", target, "\n")
  VALUE <- list()
  EXECS <- list()
  value_list <- list()
  AUC_list <- list()
  ci <- list() 
  # ingest all the data
  idx = 0
  max_value = 0.0
  min_value = .Machine$integer.max
  maxtrials = 0
  xmax = 0

  for (idx in 1:length(algnames)) {
      alg <- algnames[idx]
      
      # Get the data in the right format
      fname <- paste(inputprefix, alg, inputpostfix, sep="_")
      DATA = grabData(inputdir, fname)
      EXECS[[alg]] <- DATA["Iteration"]
      VALUE[[alg]] <- DATA[fieldname]

      # Number of samples
      samples = length(DATA["Iteration"][,])
      # find max Y
      max_y = max(DATA[fieldname])
      if (max_y > max_value) { max_value <- max_y }
      min_y = min(DATA[fieldname])
      if (min_y < min_value) { min_value <- min_y }
      # find max X
      duration = max(DATA["Iteration"])
      if (duration > maxtrials) { maxtrials <- duration }
      
      # get individual data
      DATA=grabData(inputdir, paste(inputprefix,alg,statpostfix,sep="_"))
      value_list[[alg]] <- DATA[fieldname][,1] # $map_size
      data_value = DATA[fieldname][,1]
      min_cur_value = min(data_value)
      max_cur_value = max(data_value)
      # it is necessary to perturb the data a bit because the expectation for boot function is that the data is not uniform
      for (j in 1:length(data_value)) {
        if (data_value[j] == min_cur_value) {data_value[j] = data_value[j] + j * 1E-8}
        if (data_value[j] == max_cur_value) {data_value[j] = data_value[j] - j * 1E-8}
      }
      
      # get the confidence interval
      bootobject <- boot(data=data_value, statistic=BootMean, R=2000)
      bootresult <- boot.ci(bootobject)$bca
      ci[[alg]] = c(bootresult[4], bootresult[5])
      if (ci[[alg]][2] > max_value) {max_value = ci[[alg]][2]}
      if (ci[[alg]][1] > max_value) {max_value = ci[[alg]][1]}
       
      AUC_list[[alg]] <- DATA[paste0(fieldname,"_AUC")][,1] # map_size_AUC
  }
  
  # get the statistical conclusions if required
  if (include_conclusion) {
    conclusion <- getConclusion(algnames, value_list, "crashes")
    conclusion_AUC <- getConclusion(algnames, AUC_list, "AUC")
  }

  cat("Preparing scales")
  # get the x and y scales nice...
  raw_scales = AdjustScales(maxtrials, min_value, max_value, 0, 1) #2, 0.01)  
 
  # Setup the plot
  num_tables = 0
  if (include_conclusion) {num_tables = 2}
  figParam = GetFigParams(num_tables)
  cat(figlongwidth, figheight, "\n")
  pdf(iname,width=figParam$width/72.0,height=figParam$height/72.0)
  value_dev <- dev.cur()
  SetLayout(num_tables)
  PlotMain(cur_dev=value_dev, xmin=0, xmax=raw_scales$xmax, xdiv=raw_scales$xdiv, 
    ymin=0, ymax=raw_scales$ymax, ydiv=raw_scales$ydiv, main_lab=title, 
    sub_lab=sublab, xlab=raw_scales$xlab, ylab=ylab,
    xaxis_offset=figParam$xaxis_offset, yaxis_offset=figParam$yaxis_offset, xlabel_div=raw_scales$xdiv)

  cat(str(raw_scales))
  # actually plotting the data points
  for (idx in 1:length(algnames)) {
    alg = algnames[idx]
    X1 <- EXECS[[alg]]
    Y1 <- VALUE[[alg]]
    colour = colours[idx]
    line_type = lntypes[idx]
    symbol = symbols[idx]
    dev.set(value_dev)
    # plot as a line
    points(X1$Iteration, # X
           Y1[,1], # Y
           type='l', col = colour, lwd = 5, lty = line_type)

    # add exclusive shape in a predetermined locations
    X_DATA = X1[,1]
    Y_DATA = Y1[,1]
    threshold = raw_scales$xdiv / 2.0
    for (execs_it in 1:length(X_DATA)) {
      if (X_DATA[execs_it] > threshold) {
        threshold = threshold + raw_scales$xdiv / 2.0
        points(X_DATA[execs_it], Y_DATA[execs_it], col = colour, lwd = 5, pch = symbol)
      }
    }
  }
  
  # plot the confidence interval at the end
  PlotCI(ci, raw_scales$xmax)
#  PlotLegend(legendpos, legendinset) # plot the legend, apparently not needed anymore
  
  if (include_conclusion) {
    tt <- ttheme_default(base_size=12)
    PlotConclusion(conclusion, tt, "Conclusions about deduplicated crashes", 790) 
    PlotConclusion(conclusion_AUC, tt, "Conclusions about AUC (area under curve)", 1185)
  }

  dev.off(value_dev)
  cat ("finishing\n")

}

