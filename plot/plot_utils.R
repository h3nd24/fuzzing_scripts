#!/usr/bin/Rscript
#!/usr/bin/env Rscript 
#library(methods)
#library(stringr)
library(effsize)
library(optparse)
library(grid)
library(vcd)
library(gridExtra)
library(gridBase)
library(gtable)
library(scales)
figlongwidth=1600
figheight=700
### MODEL PARAMETERS ###
algnames = c("empty", "moonshine_size")
target = "pdf"
max_experiment = c(20, 20)
time_limit = "18h"
possible_names = list() # expansions on possible categories in the plot. This is currently hard coded. The good thing is, it can be reused many times for various plots
possible_names[["cmin"]] <- "CMIN"
possible_names[["moonshine"]] <- "ML-U"
possible_names[["moonshine_size"]] <- "ML-S"
possible_names[["moonshine_time"]] <- "ML-T"
possible_names[["empty"]] <- "Empty"
possible_names[["full"]] <- "Full"
possible_names[["minset"]] <- "MS-U"
possible_names[["greedy"]] <- "ML-G"
possible_names[["greedy_mod"]] <- "ML-G (Mod)"
possible_names[["random"]] <- "Rand"
possible_names[["moonshine_size_mod"]] <- "ML-S (Ordered)"
possible_names[["moonshine_size_rs"]] <- "MoonLight-S RS"
possible_names[["minset_rs"]] <- "Unweighted Minset (RS)"
full_target <- list("sox" = "SoX - MP3", "pdf" = "poppler-0.64.0 (pdftotext) - PDF", "wav" = "SoX - WAV",
                        "ttf253" = "freetype-2.5.3 - TTF", "xml290" = "libxml2-2.9.0 - XML", "wv" = "libwv-1.2.9 - DOC",
                        "svg24020" = "librsvg-2.40.20 - SVG", "tiff409" = "libtiff-4.0.9 - TIFF",
                        "tiff409c7" = "libtiff-4.0.9 - TIFF") # expansions on the target names. I think this is not used anymore
actual_names <- list() # the actual string used in the categories
xaxis_offset = -2.5
yaxis_offset = -2

colours = c('tan3', 'turquoise3', 'red', 'blue', 'purple3', 'green3', 'gray40', 'coral4', 'deeppink3', 'black') # colour map, add if needed
symbols = c(0, 1, 2, 3, 4, 5, 6, 8, 11) # various symbols
lntypes = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1) # line types, however it is not really used

# Get the data from the CSV file
grabData = function(datastore,filename) {
  fname <- paste(datastore,filename,sep="/")
  DATA <- read.table(fname,sep=",",header=TRUE)
  return (DATA)
}

# The coverage and bug plots (majority) uses 250 as the figure height.
# Only the corpus distance need height of 700
GetFigParams = function(num_tables, height=250) { 
  if (num_tables == 0) {
    return (list("width" = 800, "height" = height, "xaxis_offset" = 0, "yaxis_offset" = 0 ))
  } else if (num_tables == 1) {
    return (list("width" = 1200, "height" = height, "xaxis_offset" = -1, "yaxis_offset" = -1.35 ))
  } else if (num_tables == 2) {
#    return (list("width" = 1600, "height" = 700, "xaxis_offset" = -1.25, "yaxis_offset" = -1.6 ))
    return (list("width" = 1600, "height" = height, "xaxis_offset" = -1.75, "yaxis_offset" = -2.25))
  } else if ((num_tables == 3) || (num_tables == 4)) {
    return (list("width" = 1600, "height" = height, "xaxis_offset" = -1.75, "yaxis_offset" = -2.25))
  } else { 
    cat ("num_tables has to be between 0 and 4 inclusive")
    quit() 
  }
  
}

SetLayout = function(num_tables) {
  if (num_tables == 0) {
    par(oma = c(1.5,2,0,0), mar = c(2, 3, 0, 0))
    par(cex.main = 1.75, cex.sub= 1.75, cex.axis=1.75, cex.lab=1.75)
  } else if (num_tables == 1) {
    layout(matrix(c(1,2), nrow = 1, ncol = 2, byrow=TRUE), widths = c(2,1))
    par(oma = c(2,2,1,0), mar = c(6, 4, 6, 2))
    par( cex.main = 2, cex.sub= 2, cex.axis=2, cex.lab=2)
  } else if (num_tables == 2) {
#    layout(matrix(c(1,2,1,3), nrow = 2, ncol = 2, byrow=TRUE),
#      widths = c(2,1), heights = c(1, 1))
    layout(matrix(c(1,2,3), nrow = 1, ncol = 3, byrow=TRUE),
      widths = c(1.83,1,1), heights = c(1, 1))
    par(oma = c(2,4,1,0), mar = c(6, 4, 6, 2))
    par( cex.main = 2, cex.sub= 2, cex.axis=2, cex.lab=2)
  } else if ((num_tables == 3) || (num_tables == 4)) {
    layout(matrix(c(1,2,3,1,4,5), nrow = 2, ncol = 3, byrow=TRUE),
      widths = c(1.83,1,1), heights = c(1, 1))
    par(oma = c(2,4,1,0), mar = c(6, 4, 6, 2))
    par(lheight=20, cex.main = 3, cex.sub= 3, cex.axis=2.75, cex.lab=3)
  } else { 
    cat ("num_tables has to be between 0 and 4 inclusive")
    quit() 
  }
  
}

PlotMain = function(cur_dev, xmin, xmax, xdiv, ymin, ymax, ydiv, main_lab, sub_lab, xlab, ylab,
  xaxis_offset, yaxis_offset, xlabel_div=1) {
  # start ploting
  dev.set(cur_dev)
  cat ("XXX", ymin, ymax, ydiv ,"\n")
  cat (xaxis_offset, yaxis_offset, " xaxis yaxis\n")
  par(lheight=0.9)
  ydiv_step = 1
  if (ymax > 10) { 
    if ((ymax / ydiv) %% 2 != 0) { ymax = ymax + ydiv }
    ydiv_step = 2
  }
#  ydiv_step = 1
  plot(0,0, type='l', col="white", sub="", xlab="", xlim = c(xmin,xmax), ylab="", ylim=c(ymin,ymax), lwd=2, axes=FALSE)
#  title(sub=sub_lab, line=4)
  title(xlab=xlab, line=0.5, outer=T)
  title(ylab=ylab, line=0.5, outer=T)
  main_labs = main_lab #paste0(main_lab[1], "\n", main_lab[2])#c(full_target[[target]], main_lab, recursive=T)
#  title(main = main_labs, line=1) # ,outer=true # removed the title for now
#  par(mar=c(5,4,4,2))
  # TODO: labelling for xdiv
#  tagsx = seq(xmin,xmax,xdiv) / xdiv
  tagsx = format(round(seq(xmin,xmax,xdiv) / xlabel_div,2))
#  tagsy = seq(ymin,ymax,ydiv)
  tagsy = round(seq(ymin,ymax,ydiv*ydiv_step),2)
  if (max(tagsy) < ymax) {tagsy = c(tagsy, max(tagsy) + 1)}
  axis(1,format(round(seq(xmin,xmax,xdiv),2), nsmall = 2),tick=TRUE, labels=tagsx, line=xaxis_offset)
  axis(2,format(tagsy, nsmall = 2),tick=TRUE, las=2, line=yaxis_offset)  #las=2 --> perpendicular labels
#  axis(4, format(round(seq(ymin2,ymax2,ydiv2),2), nsmall = 2),tick=TRUE, las=2, line=-1.5)  #las=2 --> perpendicular labels
  abline(h=seq(ymin,ymax,ydiv), v=seq(xmin,xmax, xdiv), col="grey", lty=3)
}

# The second y-axis, this is not used anymore
#PlotSecond = function(cur_dev, xmin, xmax, xdiv, ymin, ymax, ydiv, ylab) {
#  # start ploting
#  dev.set(cur_dev)
#  par(new=T)
#  plot(0,0, type='l', col=NA, sub=NA, xlab=NA, xlim = c(0,xmax), ylab=NA, ylim=c(ymin,ymax), lwd=2, axes=FALSE)
#  mtext(ylab,side=4, line=3, cex=1.15)
#  tagsy = seq(ymin,ymax,ydiv)
#  axis(4, format(round(seq(ymin,ymax,ydiv),2), nsmall = 2),tick=TRUE, las=2, line=-1.5)  #las=2 --> perpendicular labels
#}

# Plot Legend
PlotLegend = function(legend_pos, legend_inset, used_colours=colours, used_symbols=symbols) {
  par (cex = 1)
  normal_lines <- list()
  gpar_colours <- list()
  for (i in 1:length(algnames)) {
    normal_lines[[i]] <- "solid"
    gpar_colours[[i]] <- gpar(col=colours[[i]])
  }
  normal_lines <- c(normal_lines, recursive=TRUE)
  legend(x=legend_pos, legend=c(actual_names,recursive=TRUE), bg="white",
       col=used_colours, text.col=used_colours, #inset=c(0.005,0.005), #xpd=TRUE,
       lwd=4,lty=lntypes, inset=legend_inset, pt.cex=1, cex=1.2, pch=used_symbols) # inset=0.035 
}

# Get conclusions
getConclusion = function(algnames, crash_data, value_type) {
  winner <- list()
  loser <- list()
  pvallist <- list()
  vda_estimate_list <- list()
  counter <- 1
  pvalstr <- "p-value"
  win_table <- list()
  lose_table <- list()
  for (i in 1:length(algnames)) {
    win_table[[i]] <- list()
    lose_table[[i]] <- 0
  }
  cat ("################### \n")
  algnames_length <- length(algnames)
  if (algnames_length > 1) {
    for (idx1 in 2:algnames_length) {
      for (idx2 in 1:idx1) {
        if (idx1 == idx2) { 
          next
        }
        alg1 <- algnames[idx1]
        alg2 <- algnames[idx2]
        win_idx <- idx1
        lose_idx <- idx2
        u <- wilcox.test(crash_data[[alg1]],crash_data[[alg2]],exact=TRUE,alternative='greater')
        pval <- u$p.value
        if (pval > 0.5) {
          u <- wilcox.test(crash_data[[alg1]],crash_data[[alg2]],exact=TRUE,alternative='less')
          pval <- u$p.value
          win_idx <- idx2
          lose_idx <- idx1
        }
        if (pval < 0.05) {
           l <- length(win_table[[win_idx]])
           vda_result = VD.A(crash_data[[algnames[win_idx] ]], crash_data[[algnames[lose_idx] ]] )
           win_table[[win_idx]][[l + 1]] <- list("lose_idx" = lose_idx, "pval" = pval, "estimate"=vda_result$estimate)
           lose_table[[lose_idx]] <- lose_table[[lose_idx]] + 1
           cat(value_type, algnames[win_idx], algnames[lose_idx], vda_result$estimate, paste0(vda_result$magnitude, "\n"), sep=",")
           
        }
      }
    }

  # collate the result and collapse conclusions when possiblea
  # remove the collapsed conclusions first
    removed_idx <- integer(algnames_length)
    removed_counter <- 0
    for (i in 1:algnames_length) {
  #   loses against everything 
      if (lose_table[[i]] == (algnames_length - 1) ) {
        winner[[counter]] <- "everything"
        loser[[counter]] <- possible_names[[algnames[i] ]]
        pvallist[[counter]] <- "-"
        counter <- counter + 1
        removed_counter = removed_counter + 1
        removed_idx[removed_counter] <- i 
        next
      }
  #   wins against everything
      if (length(win_table[[i]]) == (algnames_length - 1) ) {
        winner[[counter]] <- possible_names[[algnames[i] ]]
        loser[[counter]] <- "everything"
        pvallist[[counter]] <- "-"
        counter <- counter + 1
        removed_counter = removed_counter + 1
        removed_idx[removed_counter] <- i 
        next
      }
    }
    for (i in 1:algnames_length) {
      if (i %in% removed_idx) { next }
      if (length(win_table[[i]]) == 0) { next }
      for (j in 1:length(win_table[[i]]) ) {
        stat <- win_table[[i]][[j]]
        if (stat$lose_idx %in% removed_idx) { next }
        winner[[counter]] <- possible_names[[algnames[i] ]]
        loser[[counter]] <- possible_names[[algnames[stat$lose_idx] ]]
        pvallist[[counter]] <- formatC(stat$pval, format="e", digits=3)
        counter <- counter + 1
      }
    }
  }
  cat ("################### \n")
  return_list <- list("winner" = winner, "loser" = loser, "pvallist" = pvallist, "len" = counter - 1)
  return (return_list)
}

# Plot Conclusion
PlotConclusion = function(conclusion, tt, title, x) {
  if (conclusion$len > 0) {
    winner = c(conclusion$winner, recursive=TRUE)
    loser = c(conclusion$loser, recursive=TRUE)
    pval = c(conclusion$pvallist, recursive=TRUE)
  } else {
    winner = c("")
    loser = c("")
    pval = c("")
  }
  data = data.frame(winner, loser, pval)
  numrows = length(winner)
  frame()
  vps <- baseViewports()
  vps$figure$x = unit(x, "points")
  pushViewport(vps$figure)
  suppressRows = c(rep("", numrows))
  colNames = c("Corpus treatment", "wins against", "p-value")
  t <- tableGrob(data, rows = suppressRows, cols = colNames, theme = tt,
    width=unit(c(13,13,5.5),c("char")) )
  titleGrob = textGrob(title)
  table <- gtable_add_rows(t, heights = grobHeight(titleGrob) + unit(5,"mm"), pos=0)
  table <- gtable_add_grob(table, titleGrob, 1, 1, 1, ncol(table))
  grid.draw(table)
  popViewport(1)
}

# Get the scales of the plot
AdjustScales = function(max_x, min_y, max_y, rounding, min_div_y) {
  xdiv = 1e6
  xlab="Iteration (x1M)"
  if (max_x > 3e8) { 
    xdiv = 1e8 
    xlab="Iteration (x100M)"
  } else if (max_x > 3e7) { 
    xdiv = 1e7 
    xlab="Iteration (x10M)"
  }
  ymin = min_y
  ydiv = max(round((max_y - min_y) / 10.0, rounding), min_div_y)
#  ydiv = 1
#  cat(max_y, min_y, ydiv)
  
  if ((max_y %% ydiv) == 0) {
    ymax = max(((max_y %/% ydiv) ) * ydiv, 1)
  } else {
    ymax = ((max_y %/% ydiv) + 1) * ydiv
  }
  
  if ((max_x %% xdiv) == 0) {  # %% == mod
    xmax = (max_x %/% xdiv) * xdiv
  } else {
    xmax = ((max_x %/% xdiv) + 1) * xdiv
  }
  return (list("xmax" = max(max_x * 10.0 / 8.5, xmax), "ymin" = ymin, "ymax" = ymax, "xdiv" = xdiv, "ydiv" = ydiv, "xlab" = xlab))
}

# Plot the confidence interval at the end of the plot
PlotCI = function(ci,  max_x_plot) {
  start_pos = 0.85 * max_x_plot
  small_xdiv = max_x_plot / 60.0
  smaller_xdiv = small_xdiv / 5.0
  for (i in 1:length(algnames)) {
    alg = algnames[i]
    xpos = start_pos + i * small_xdiv
    colour = colours[i]
    line_type = lntypes[i]
    smaller_xdiv 
    segments(x0 = c(xpos - smaller_xdiv, xpos - smaller_xdiv), y0 = c(ci[[alg]][1], ci[[alg]][2]), 
             x1= c(xpos + smaller_xdiv, xpos + smaller_xdiv), y1= c(ci[[alg]][1], ci[[alg]][2]), 
             col=colour, lwd=5)
    segments(x0 = xpos, y0 = ci[[alg]][1], x1 = xpos, y1 = ci[[alg]][2], col=colour, lwd=5, lty=line_type)
  }
}

# Getting the arithmetic mean for boot function which scrambles the index for repetitive trials
BootMean = function(x, indices) {
  mean(x[indices])
}
