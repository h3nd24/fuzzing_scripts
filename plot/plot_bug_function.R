library(png)
library(gridExtra)
library(EnvStats)
library(boot)

# Various trials at plotting speed to find bug.
# We ended up with the plotting_7, so the other plotting functions may not work properly anymore / it requires minor tweaks

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

plotting_old = function(combined_df, df_labels) {
  return (ggplot(combined_df, aes(x=Alg, y=execs_first_found, group=Alg)) +
#         geom_point(data=subset(combined_df, execs_first_found > 0), aes(color=Alg)) +
         geom_point(aes(color=Alg)) +
         stat_summary(fun.y = mean, fun.data=mod_summary, geom = "errorbar", width = 0.75, aes(color=Alg)) + 
         geom_text(data=df_labels, aes(x=Alg, y=-1000000, label=count, angle=90, color=Alg) ) +
         facet_grid(. ~ bug_id) +
#         labs(title="") + 
         xlab("Bug ID") + 
         scale_y_continuous(name="number of executions when a bug first found (x1M)", labels=div1M) + 
         theme(legend.title=element_blank(), axis.text.x = element_blank())
#         theme(axis.text.x = element_text(angle = 90, hjust = 1), legend.title=element_blank(), axis.text.x = element_blank())
  )
}

plotting_1 = function(combined_df, hist_breaks) {
  return ( ggplot(combined_df, aes(x=execs_first_found, group=Alg), na.rm=F) +
         geom_histogram(breaks=hist_breaks, aes(color=Alg, fill=Alg), position="dodge", na.rm=F) + 
         facet_wrap(. ~ bug_id, nrow=3) +
         xlab("Executions when bug first found") + 
         theme(legend.title=element_blank(), axis.text.x = element_blank()) )
}

plotting_3 = function(combined_df) {
  return ( ggplot(subset(combined_df, execs_first_found > 0), aes(x=Alg, group=bug_id), na.rm=F) +
         geom_histogram(stat="count", aes(fill=bug_id), position="dodge") +
         labs(fill="Bug ID") +  
         xlab("Distillation techniques") +
         ylab("How many times a particular bug is found over 30 experiments") )
}

plotting_4 = function(combined_df, algnames, bugs, maxexecs, df_labels) {
  new_df = data.frame( Alg=character(),
    bug_id=character(),
    execs_first_found=integer() )
  levels(new_df$bug_id) = bugs
  levels(new_df$Alg) = algnames
  cat(str(combined_df))
  for (alg in algnames) {
    for (bug in bugs) {
      sub_df = subset(combined_df, Alg == alg & bug_id == bug & execs_first_found > 0, select=execs_first_found)
      avg = 0L
      if (length(sub_df$execs_first_found) > 0) { avg = maxexecs - mean(as.numeric(sub_df[["execs_first_found"]] ))}
      new_df[nrow(new_df)+1,] = c(alg, bug, avg)
    }
  }
  new_df = transform(new_df, execs_first_found = as.numeric(execs_first_found))
  shade_start = seq(1,5)
  dummy_stripes = data.frame(xstart = shade_start-0.5, xend=shade_start+0.5, col=algnames)
  dummy_col_short = c('gray', 'white', 'gray', 'white', 'gray')
  alg_col = setNames(dummy_col_short, algnames)
  return ( ggplot(new_df) + #ggplot(new_df, aes(x=Alg, y=execs_first_found, group=Alg), na.rm=F) +
         geom_point(data=new_df, aes(x=Alg, y=execs_first_found, group=Alg, color=Alg), position="dodge") +
         geom_rect(data=dummy_stripes, aes(xmin=xstart, xmax=xend, ymin=0, ymax=Inf, fill=col), alpha=0.4) +
         scale_fill_manual(breaks=algnames, values=alg_col ) + 
         geom_point(data=new_df, aes(x=Alg, y=execs_first_found, group=Alg, color=Alg), position="dodge") + # add another layer
         facet_grid(. ~ bug_id) +
         geom_text(data=df_labels, aes(x=Alg, y=-1000000, label=count, angle=90, color=Alg) ) +
         xlab("Distillation techniques") +
         ylab("Average number of executions when a bug first found until the experiments finished")  +
         theme(legend.title=element_blank(), axis.text.x = element_blank()) # +
         #theme(panel.background=element_blank()) 
         )
}

plotting_5 = function(combined_df, algnames, bugs, maxexecs, df_labels) {
  new_df = data.frame( Alg=character(),
    bug_id=character(),
    execs_first_found=integer() )
  levels(new_df$bug_id) = bugs
  levels(new_df$Alg) = algnames
  cat(str(combined_df))
  cat(str(df_labels))
  for (alg in algnames) {
    for (bug in bugs) {
      sub_df = subset(combined_df, Alg == alg & bug_id == bug & execs_first_found > 0, select=(execs_first_found))
      count_bugs = as.numeric(subset(df_labels, Alg == alg & bug_id == bug, select=count))
      avg = maxexecs - ( (sum(as.numeric(sub_df[["execs_first_found"]] )) + maxexecs * (30 - count_bugs) ) %/% 30)
      new_df[nrow(new_df)+1,] = c(alg, bug, avg)
    }
  }
  new_df = transform(new_df, execs_first_found = as.numeric(execs_first_found))
  shade_mid = seq(1,length(bugs))
  shade_start = shade_mid - 0.5
  shade_start[1] = 0
  shade_end = shade_mid + 0.5
  shade_end[length(shade_end)] = length(bugs) + 1
  dummy_stripes = data.frame(xstart = shade_start, xend=shade_end, col=bugs)
  dummy_colours = c()
  alternating_stripe_colour = c('gray', 'white')
  for (bug in bugs) {
    dummy_colours = rbind(dummy_colours, c(bug = alternating_stripe_colour[alternating_counter]) )
    alternating_counter = (alternating_counter %% 2) + 1
  }
  ymin = - (max_execs %/% 25)
#  dummy_col_short = c('gray', 'white', 'gray', 'white', 'gray')
#  dummy_colours = setNames(dummy_col_short, bugs)
  return ( ggplot(new_df) + #ggplot(new_df, aes(x=Alg, y=execs_first_found, group=Alg), na.rm=F) +
         geom_point(data=new_df, aes(x=bug_id, y=execs_first_found, group=bug_id, color=bug_id), position="dodge") +
         geom_rect(data=dummy_stripes, aes(xmin=xstart, xmax=xend, ymin=0, ymax=Inf, fill=col), alpha=0.4) +
         scale_fill_manual(breaks=algnames, values=dummy_colours ) + 
#         geom_point(data=new_df, aes(x=bug_id, y=execs_first_found, group=bug_id, color=bug_id), position="dodge") + # add another layer
         geom_line(data=new_df, aes(x=bug_id, y=execs_first_found, group=bug_id, color=bug_id), position="dodge") + # add another layer
         facet_grid(. ~ Alg) +
         geom_text(data=df_labels, aes(x=bug_id, y=ymin, label=count, angle=90) ) +
         xlab("Distillation techniques") +
         scale_y_continuous("Average number of executions when a bug first found until the experiments finished", labels=div1M, limit=c(ymin, max_execs))  +
         theme(legend.title=element_blank(), axis.text.x = element_blank()) # +
         #theme(panel.background=element_blank()) 
         )
}


tick_label = function(x) {
  ret = c()
  for (e in x) {
    if (is.na(e)) {
      ret = c(ret,0)
      ret[length(ret)] = NA
      next
    }
    if (e%%1!=0) 
    {  
      ret = c(ret,"")
      next
    }
    ret = c(ret, bquote(2^.(e)))
  }
  return (ret)
}

plotting_6 = function(combined_df, algnames, possible_names, bugs, output_prefix) {
  sub_data = as.numeric( combined_df[,c('time_first_found')] )
  combined_df$time_first_found = sapply(sub_data, function(x) ifelse(x > 0.0, 1.0 / x, 0.0))
  averages = list()
  for (alg_raw in algnames) {
    alg = possible_names[[alg_raw]]
    sub_data = subset(combined_df, Alg==alg)
    for (bug in bugs) {
      sub_data_bug = subset(sub_data, bug_id==bug, select=(time_first_found))
      averages[[alg]][[bug]] = mean(sub_data_bug$time_first_found)
    }
  }
  # load the bomb image
  img <- readPNG("bomb-transparent.png")
  g <- rasterGrob(img, interpolate=TRUE)

  # stripes
  shade_mid = seq(1,length(bugs))
  shade_start = shade_mid - 0.5
#  shade_start[1] = 0
  shade_end = shade_mid + 0.5
#  shade_end[length(shade_end)] = length(bugs) + 1
  dummy_stripes = data.frame(xstart = shade_start, xend=shade_end, col=bugs)
  alternating_stripe_colour = c('gray85', 'gray95')
  alternating_darker_colour = c('gray70', 'gray88')

  # for the x location of the bomb
  bug_mid = list()
  counter = 1
  reference = list()
  for (bug in bugs) {
    bug_mid[[bug]] = counter
    counter = counter + 1
    reference[[bug]] = 0
  }
  # find the best speed for each bug
  for (alg_raw in algnames) {
    s = possible_names[[alg_raw]]
    for (bug in bugs) {
      if (averages[[s]][[bug]] > reference[[bug]]) reference[[bug]] = averages[[s]][[bug]]
    }
  }

  # finding the minimum and maximum values
  all_plots = list() 
  counter = 1
  min_value = 100000 # arbitrary value for the location of bomb
  max_value = -100000 # arbitrary value for the maximum value
  # get the min and max values
  for (alg_raw in algnames) {
    s = possible_names[[alg_raw]]
    for (bug in bugs) {
      if (averages[[s]][[bug]] == 0) { next }
      value = log2(averages[[s]][[bug]] / reference[[bug]])
#      for (t in actual_names) {
#        if (s == t) { next }
#        if (averages[[t]][[bug]] > 0) {
#          value = log10(averages[[s]][[bug]] / averages[[t]][[bug]])
#          cat(s, t, averages[[s]][[bug]], averages[[t]][[bug]], "\n")
          if (value < min_value) { min_value = value }
          if (value > max_value) { max_value = value } 
#        }
#      }
    }
  }
  # for now assume that data points are never uniform
  value_height = max_value - min_value
  bomb_location = min_value - value_height / 4.0
  small_y_div = value_height / 10.0
#  cat (min_value, max_value, value_height, bomb_location, small_y_div, "\n")
  
#  g_legend<-function(a.gplot)  {
#    tmp <- ggplot_gtable(ggplot_build(a.gplot))
#    leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
#    legend <- tmp$grobs[[leg]]
#    return(legend)
#  }

  counter = 1
  combined_legend = NA
  crosshatch_gp = gpar(lwd=0.01, lex=0.5, col="gray55")
  crosshatch_x = unit(c(0, 1), "npc")
  crosshatch_y_down = unit(c(1, 0), "npc")
  upline = linesGrob(gp=crosshatch_gp)
  downline = linesGrob(x=crosshatch_x, y=crosshatch_y_down, gp=crosshatch_gp)
  for (alg_raw in algnames) {
    s = possible_names[[alg_raw]]
    new_df = data.frame(Alg=character(), bug_id=character(), speedup=numeric() )
    bomb_df = data.frame(Alg=character(), bug_id=character())
    levels(new_df$bug_id) = bugs
    levels(new_df$Alg) = actual_names
    levels(bomb_df$bug_id) = bugs
    levels(bomb_df$Alg) = actual_names
    non_zero_values = c()
    for (bug in bugs) {
      if (averages[[s]][[bug]] == 0) {
        bomb_df[nrow(bomb_df)+1,] = c(s, bug )
        next
      }
#      for (t in actual_names) {
#        if (s == t) { next }
#        if (averages[[t]][[bug]] > 0) {
#        value = log10(averages[[s]][[bug]] / averages[[t]][[bug]])
        slowdown = averages[[s]][[bug]] / reference[[bug]]
        value = log2(slowdown)
        new_df[nrow(new_df)+1,] = c(s, bug, value )
        non_zero_values = c(non_zero_values, slowdown)
#        }
#      }
    }

#    shown_df = new_df
    for (bug in bomb_df$bug_id) {
      new_df[nrow(new_df)+1,] = c(s, bug, 2*bomb_location)
    } 
    new_df = transform(new_df, speedup = as.numeric(speedup))
#    shown_df = transform(shown_df, speedup = as.numeric(speedup))
#    geo_mean_data = data.frame(x = numeric(), y = numeric(), txt = character(), stringsAsFactors=F)
#    geo_mean_x = length(bugs) %/% 2 + 0.5
#    geo_mean_y = small_y_div * 0.95
#    geo_mean_text = ifelse (length(non_zero_values) > 0, paste0("geometric mean = ", round(geoMean(non_zero_values),3)), "geometric mean = N/A")
#    geo_mean_data[1,] = c(geo_mean_x, geo_mean_y, geo_mean_text)
#    cat(str(geo_mean_data))
    p = ggplot() 

# crosshatches
#    crosshatch_div = 0.75 * small_y_div
#    ystarts = seq(3 * min_value, max_value + crosshatch_div, crosshatch_div)
#    for (ystart in ystarts) {
#      p = p + 
#        annotation_custom(grob=upline, xmin=0.5, xmax = length(bugs) + 0.5, ymin = ystart, ymax=ystart + value_height) + 
#        annotation_custom(grob=downline, xmin=0.5, xmax = length(bugs) + 0.5, ymin = ystart, ymax=ystart + value_height)
#    }

    p = p + 
        geom_point(data=new_df, aes(x=bug_id, y=speedup, color=Alg), position=position_dodge(width=0.5), size=10) +
        theme(panel.background=element_blank(), axis.text.y=element_text(size=30),
          axis.title.y=element_blank(),
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          plot.margin=unit(c(0,0,0,0.25), "cm")) +
        scale_y_continuous(limits=c(bomb_location - small_y_div, max_value), labels=tick_label) +
        scale_x_discrete(breaks=seq(1,10))# + 
#        geom_rect(data=dummy_stripes, aes(xmin=xstart, xmax=xend, ymin=-Inf, ymax=Inf, fill=col), show.legend=F, alpha=1) +
#        scale_fill_manual(breaks=bugs, values=dummy_colours ) + 
#        scale_alpha_discrete(breaks=bugs, range=alpha_rect) +
#        geom_text(data=geo_mean_data, aes(x=as.numeric(x), y=as.numeric(y), label=txt), size=10, fontface="bold") + 
#        xlab("Bugs") + 
#        ylab("Speedup") +
#        labs(color="Compared against", shape="Compared against") + 
#        ggtitle(s) #+
#        theme(legend.text=element_text(size=6))

    # lighter color to enable the background crosshatches to appear
    alternating_counter = 1
    for (bug in bugs) {
      if (bug %in% bomb_df$bug_id) {
        p = p + annotate("rect", xmin=bug_mid[[bug]] - 0.5, xmax=bug_mid[[bug]] + 0.5, ymin=-Inf, ymax=Inf, fill="gray40")
      } else {
        p = p + annotate("rect", xmin=bug_mid[[bug]] - 0.5, xmax=bug_mid[[bug]] + 0.5, ymin=-Inf, ymax=Inf, fill=alternating_stripe_colour[alternating_counter])
      }
      alternating_counter = (alternating_counter %% 2) + 1 
    }
    p = p + 
        geom_hline(yintercept=0, size=0.1) +
        geom_point(data=new_df,aes(x=bug_id, y=speedup, color=Alg), position=position_dodge(width=0.5), size=10)
    for (bug in bomb_df$bug_id) {
# bomb
#      p = p + annotation_custom(g, xmin=bug_mid[[bug]] - 0.5, xmax=bug_mid[[bug]] +0.5, ymin=bomb_location-small_y_div, ymax=bomb_location+small_y_div)

# text
#      g = textGrob("Bug not found", rot = 270, gp=gpar(fontsize=32))
#      p = p + annotation_custom(g, xmin=bug_mid[[bug]] - 0.5, xmax=bug_mid[[bug]] +0.5, ymin=min_value, ymax=max_value)

# crosshatches
#       xmin = bug_mid[[bug]] - 0.5
#       xmax = bug_mid[[bug]] + 0.5
#       ymin = bomb_location
#       ymax = 0
#       crosshatch_div = 4 * small_y_div
##       crosshatch_div = unit(0.1,  
#       ystarts = seq(1.2 * ymin, 1, crosshatch_div)
#       yends = seq(1.2 * ymin + crosshatch_div, 1 + crosshatch_div, crosshatch_div)
#       cat(str(ystarts))
#       cat(str(yends))
#       counter = 1
#       for (i in 1:length(ystarts)) {
#         p = p + annotation_custom(grob=upline, xmin=xmin, xmax=xmax, ymin = ystarts[counter], ymax=yends[counter])
#         p = p + annotation_custom(grob=downline, xmin=xmin, xmax=xmax, ymin = ystarts[counter], ymax=yends[counter])
#         counter = counter + 1
#       }
    
    }




#    if (counter > 1) { p = p + theme(legend.position="none")  }
#    else { 
#      combined_legend = g_legend(p) 
    p = p + theme(legend.position="none")
#    }
    output_file = paste0(output_prefix,"_",alg_raw,".pdf")
    ggsave(output_file, plot=p, device="pdf")
#    all_plots[[counter]] = p
#    ggsave(paste0("test_plot_", counter), plot=p, device="pdf")
    
    counter = counter + 1
  }
#  all_plots[[counter]] = combined_legend
#  pl = grid.arrange(grobs=all_plots, combined_legend) #, top=title)
#  pl = do.call(grid.arrange, c(all_plots, top="Speedup Plot"))
  return (p) 
}

BootMean = function(x, indices) { mean(x[indices]) }

plotting_7 = function(combined_df, algnames, possible_names, bugs, output_prefix) {
  sub_data = as.numeric( combined_df[,c('time_first_found')] )
  combined_df$time_first_found = sapply(sub_data, function(x) ifelse(x > 0.0, 1.0 / x, 0.0))
  averages = list() # getting the average value
  best = list()     # getting the best trial of all
  ci_values = list()  # for calculating the confidence interval
  for (alg_raw in algnames) {
    alg_name = possible_names[[alg_raw]]
    sub_data = subset(combined_df, Alg==alg_name)
    for (bug in bugs) {
      sub_data_bug = subset(sub_data, bug_id==bug, select=(time_first_found)) # subset the data based on bug
      averages[[alg_name]][[bug]] = mean(sub_data_bug$time_first_found)
      best[[alg_name]][[bug]] = max(sub_data_bug$time_first_found)
      if (averages[[alg_name]][[bug]] == 0) {
        ci_values[[alg_name]][[bug]] = c(0,0)
        next
      }
      # calculating the confidence interva
      data_for_boot = sub_data_bug$time_first_found
      bootobject <- boot(data=data_for_boot, statistic=BootMean, R=2000)
      bootresult <- boot.ci(bootobject)$bca
      ci_values[[alg_name]][[bug]] = c(bootresult[4], bootresult[5])
    }
  }

  alternating_stripe_colour = c('gray85', 'gray95')
  alternating_darker_colour = c('gray70', 'gray88')

  # for the x location of the bomb
  bug_mid = list()
  counter = 1
  reference = list()
  for (bug in bugs) {
    bug_mid[[bug]] = counter
    counter = counter + 1
    reference[[bug]] = 0
  }
  # find the best speed for each bug
  for (alg_raw in algnames) {
    s = possible_names[[alg_raw]]
    for (bug in bugs) {
#      if (averages[[s]][[bug]] > reference[[bug]]) reference[[bug]] = averages[[s]][[bug]]
      if (best[[s]][[bug]] > reference[[bug]]) reference[[bug]] = best[[s]][[bug]]
    }
  }

  # finding the minimum and maximum values
  all_plots = list() 
  counter = 1
  min_value = 100000 # arbitrary value for the location of bomb
  max_value = -100000 # arbitrary value for the maximum value
  # get the min and max values
  for (alg_raw in algnames) {
    s = possible_names[[alg_raw]]
    for (bug in bugs) {
      if (averages[[s]][[bug]] == 0) { next }
      value = log2(averages[[s]][[bug]] / reference[[bug]])
      ci_1 = 0
      ci_2 = 0
      if (ci_values[[s]][[bug]][1] != 0) { ci_1 = log2(ci_values[[s]][[bug]][1] / reference[[bug]]) }
      if (ci_values[[s]][[bug]][2] != 0) { ci_2 = log2(ci_values[[s]][[bug]][2] / reference[[bug]]) }
      min_val = min(value, ci_1, ci_2)
      max_val = max(value, ci_1, ci_2)
      if (min_val < min_value) { min_value = min_val }
      if (min_val > max_value) { max_value = max_val } 
    }
  }
  # for now assume that data points are never uniform
  max_value = max(0, max_value)
  value_height = max_value - min_value
  bomb_location = min_value #- value_height / 4.0
  small_y_div = value_height / 10.0
  smallest_value = value_height / 25.0
  tick_grob = linesGrob(x=unit(c(0.5,0.5), "npc"), y=unit(c(0,1), "npc"))
  y_tick = small_y_div / 5

  min_ref = list()
  corpus_ref = list()
  for (bug in bugs) {
    min_ref[[bug]] = 1
    corpus_ref[["cmin"]][[bug]] = 1
    corpus_ref[["minset"]][[bug]] = 1
    corpus_ref[["moonshine_size"]][[bug]] = 1
  }
  for (alg_raw in algnames) {
    s = possible_names[[alg_raw]]
#    new_df = data.frame(Alg=character(), bug_id=character(), speedup=numeric())
    new_df = data.frame(Alg=character(), bug_id=character(), speedup=numeric(), ci_1=numeric(), ci_2=numeric())
    bomb_df = data.frame(Alg=character(), bug_id=character())
    levels(new_df$bug_id) = bugs
    levels(new_df$Alg) = actual_names
    levels(bomb_df$bug_id) = bugs
    levels(bomb_df$Alg) = actual_names
    non_zero_values = c()
    for (bug in bugs) {
      if (averages[[s]][[bug]] == 0) {
        bomb_df[nrow(bomb_df)+1,] = c(s, bug )
        next
      }
      slowdown = averages[[s]][[bug]] / reference[[bug]]
      value = min(log2(slowdown), smallest_value)
      cat(str(ci_values[[s]][[bug]]))
      ci_1 = log2(ci_values[[s]][[bug]][2] / reference[[bug]]) # CI 1
      ci_2 = log2(ci_values[[s]][[bug]][1] / reference[[bug]]) # CI 2
      cat(ci_1, ci_2, "\n")
      new_df[nrow(new_df)+1,] = c(s, bug, value, ci_1, ci_2)
      if (alg_raw != "cmin" && alg_raw != "empty") {
#      non_zero_values = c(non_zero_values, values)
        if (min_ref[[bug]] > value) min_ref[[bug]] = value # get the minimum reference value out of ML-S and MS-U
      }
      corpus_ref[[alg_raw]][[bug]] = value
    }

    for (bug in bomb_df$bug_id) {
      new_df[nrow(new_df)+1,] = c(s, bug, 2*bomb_location, 2*bomb_location, 2*bomb_location)
    }
 
    new_df = transform(new_df, speedup = as.numeric(speedup), ci_1 = as.numeric(ci_1), ci_2 = as.numeric(ci_2))
    p = ggplot() 
    p = p + 
        scale_x_discrete(limits=bugs) + 
        scale_y_continuous(limits=c(bomb_location - smallest_value, max_value), labels=tick_label) + 
        theme(panel.background=element_blank(), axis.text.y=element_text(size=30), axis.title.y=element_blank(),
          axis.title.x=element_blank(), axis.text.x=element_blank(),
          plot.margin=unit(c(0,0,0,0.5), "cm"), legend.position="none") 

    # lighter color to enable the background crosshatches to appear
    alternating_counter = 1
    for (bug in bugs) {
      if (! bug %in% bomb_df$bug_id) {
        p = p + annotate("rect", xmin=bug_mid[[bug]] - 0.5, xmax=bug_mid[[bug]] + 0.5, ymin=-Inf, ymax=Inf, fill="gray90")
      }
    }
    p = p + 
        geom_hline(yintercept=0, size=0.25) +
        geom_bar(data=new_df, stat="identity", aes(x=bug_id, y=speedup, fill=Alg), position=position_dodge(width=0.5), size=10) +
        geom_errorbar(data=new_df, aes(x=bug_id, ymax=ci_1, ymin=ci_2))
    for (bug in bugs) {
#      g = textGrob("Bug not found", rot = 270, gp=gpar(fontsize=32))
      if (! bug %in% bomb_df$bug_id) {
        bug_label_grob = textGrob(bug, gp=gpar(fontsize=32))
        p = p + annotation_custom(bug_label_grob, xmin=bug_mid[[bug]] - 0.5, xmax=bug_mid[[bug]] + 0.5, ymin=min_value, ymax=max_value) 
      }
      p = p + annotation_custom(tick_grob, xmin=bug_mid[[bug]] - 0.5, xmax=bug_mid[[bug]] + 0.5, ymin=-y_tick, ymax=y_tick)
    }
    for (i in 1:(length(bugs) )) { p = p + geom_vline(xintercept = i - 0.5, color="gray90") }
    p = p + geom_vline(xintercept=length(bugs) + 0.5, color="gray90")

    output_file = paste0(output_prefix,"_",alg_raw,".pdf")
    figwidth = 2*length(bugs) + 0.5
    if (length(bugs) <= 2) { figwidth = 2.75*length(bugs) + 0.5} # hack for pdf
    ggsave(output_file, plot=p, device="pdf", width=figwidth, units="cm")
    
    counter = counter + 1
  }

  # get the slowdown for cmin
  sum_diff = 0
  cat ("CMIN: \n")
  for (bug in bugs) {
    if (corpus_ref[["cmin"]][[bug]] < 1 && min_ref[[bug]] < 1) {
      cat(bug, min_ref[[bug]] - corpus_ref[["cmin"]][[bug]], "\n")
      sum_diff = sum_diff + min_ref[[bug]] - corpus_ref[["cmin"]][[bug]]
    }
  }
  cat ("Sum =", sum_diff, "\n")

  cat ("ML-S vs MS-U: \n")
  sum_diff = 0
  for (bug in bugs) {
    if (corpus_ref[["moonshine_size"]][[bug]] < 1 && corpus_ref[["minset"]][[bug]] < 1) {
      cat(bug, corpus_ref[["moonshine_size"]][[bug]] - corpus_ref[["minset"]][[bug]], "\n")
      sum_diff = sum_diff + corpus_ref[["moonshine_size"]][[bug]] - corpus_ref[["minset"]][[bug]]
    }
  }
  cat ("Sum =", sum_diff, "\n")

  return (p) 
}
