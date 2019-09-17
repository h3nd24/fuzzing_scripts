#!/usr/bin/Rscript
#!/usr/bin/env Rscript 

# Script to plot the overall legend for bugs overtime plots (result of "generate_bug_plot_data.sh").

source(file="plot_utils.R")

option_list <- list(
  make_option("--algnames", default="full cmin minset moonshine_size empty random", help="corpus treatment"),
  make_option("--output", default="plot.pdf", help="output file name")
)
opt <- parse_args(OptionParser(option_list=option_list))
algnames <- unlist (strsplit(opt$algnames, " ") )
iname = opt$output

for (i in 1:length(algnames)) {
  if (algnames[i] %in% names(possible_names)) {
    actual_names[[i]] <- possible_names[[algnames[i]]]
  } else { actual_names[[i]] <- algnames[i] }
#  cat (paste(i,actual_names[[i]], algnames[i], possible_names[[algnames[i]]], sep=" "))
}

pdf(iname, width=8, height=0.75)
par(oma = c(1.5,0,0,0), mar = c(0, 0, 0, 0))
plot(NULL ,xaxt='n',yaxt='n',bty='n',ylab='',xlab='', xlim=0:1, ylim=0:1)
legend("center", legend = actual_names, pch=symbols, lwd=5, lty=lntypes, 
    col = colours, text.col=colours, horiz=T, text.width=0.11)
dev.off()
