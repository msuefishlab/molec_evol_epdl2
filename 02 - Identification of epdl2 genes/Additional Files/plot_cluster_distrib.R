#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library(ggplot2)
library(reshape2)
library(ggforce)

#import data
data <- read.delim(file = args[1], sep = '\t', header = TRUE)

#reshape data
data.r <- melt(data, id="reads_pct")

#plot
p1 <- ggplot(data = data.r, aes(x = reads_pct, y = value, color=variable, shape=variable)) + scale_shape_manual(values=1:nlevels(data.r$variable))
p2 = p1 + labs(x="% of reads", y = "No. of clusters", title = args[2], color = "parameters", shape = "parameters") 
p3 = p2 + geom_jitter(width = 0.1, height = 0.1, alpha = 0.85, size = 0.9)
p4 = p3 + facet_zoom(ylim = c(0,4), zoom.size = 2.2)
p5 = p4 + geom_vline(xintercept = 2.5, lwd = 0.25)

#save
outname=paste0(args[2],"_cluster_distrib.pdf")
ggsave(outname, p5, "pdf", width = 9, height = 4.5, units = "in")
