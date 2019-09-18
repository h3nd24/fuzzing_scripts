library(optparse)

# TAGS: coverage_over_time, bugs_over_time 
# calculate the AUC and the total bugs for each trial

option_list <- list(
  make_option("--algnames", default="cmin", help="corpus treatment"),
  make_option("--maxtrials", default="20", type="character", help="max experiments for each corpus treatment"),
  make_option("--inputdir", default=".", help="Directory containing the plot data, .e.g, \"dedup_plot_data\""),
  make_option("--outputdir", default="plot_data_stats", help="Directory containing the plot data, default to \"plot_data_stats\""),
  make_option("--inputprefix", default="plot_data", help="input file prefix, e.g., \"pdf_18h_bug_crashes\""),
  make_option("--outputprefix", default="plot_data", help="outfile prefix"),
  make_option("--outputpostfix", default="raw_display_data", help="outfile postfix"),
  make_option("--fieldname", default="map_size", help="field of interest apart from 'Iteration', output from previous script has possible field name of 'num_crashes' or 'map_size'")
)
opt <- parse_args(OptionParser(option_list=option_list))
algnames <- unlist (strsplit(opt$algnames, " ") )
max_experiment = unlist (strsplit(opt$maxtrials, " ") )
cat(str( opt))
datastore = opt$inputdir
outputdir = opt$outputdir
prefix = opt$inputprefix
outputpostfix = opt$outputpostfix
outputprefix = opt$outputprefix
fieldname = opt$fieldname

grabData = function(datastore,filename) {
  fname <- paste(datastore,filename,sep="/")
  DATA <- read.table(fname,sep=",",header=TRUE)
  return (DATA)
}

AUC = function(X,Y) {
    # function to compute the area under the curve Y = f(X)
    Q = length(X[,])
    A <- 0.0
    for (i in 1:(Q-1)) {
        dX = 1.0 * (X[i+1,1] - X[i,1])
        fy = 1.0 * Y[i,1]
        A = A + fy * dX
    }
    return (A)
}

{
  for (idx in 1:length(algnames)) {
    alg = algnames[idx]
    fname = paste(outputdir, paste(outputprefix,alg,outputpostfix, sep="_"), sep="/")
    cat("No", fieldname, paste0(fieldname, "_AUC\n"), sep=",", file=fname)
    for (i in 1:max_experiment[idx]) {
      cat("ALG: ", alg, i)
      DATA = grabData(datastore, paste(prefix,alg,i,sep="_"))
      value = max(DATA[fieldname])
      value_AUC = AUC(DATA["Iteration"], DATA[fieldname])
      cat(i, value, paste0(value_AUC,"\n"), sep=",", file=fname,append=T)
      cat(",", fieldname,": ", value, value_AUC)
      cat("\n")
    }
  }
}
