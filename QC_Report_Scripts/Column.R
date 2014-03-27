#!/usr/bin/env Rscript

syntax_error = "Correct syntax: ./column_precision.R <CSV> <'Average' or 'CV'> <output_png>"
args<-commandArgs(TRUE)
if (length(args) != 3) { stop(syntax_error) }
file_path = args[1]													# RFU Avg or CV data for NIMBUS
data_type = args[2]
fname = args[3]

data <- read.csv(file=file_path,head=TRUE,sep=",")					# Contains a date, well, and statistic
data <- data[order(data$date,as.numeric(substr(data$group,5,6))),]	# Sort by date, well
dates = as.Date(unique(data$date))

if(data_type != "Average" && data_type != "CV") { stop(syntax_error) }
if(data_type == "Average") { main_title = "RFU avg by column over time"; y_label = "RFU Average"; log_scale="y"; y_lim=c(10,max(data$statistic)); colls = seq(1,12,1) }
if(data_type == "CV") { main_title = "Median RFU CV by column over time"; y_label = "Median RFU CV"; log_scale=""; y_lim=c(0,max(0.4,max(data$statistic))); colls = seq(1,12,1) }

png(fname,width=800,height=500)
par(mar=c(6, 5, 4, 1))
plot(NA, xlim=c(1,length(dates)), ylim=y_lim, axes=FALSE, ann=FALSE, xaxs="r", log=log_scale)
mtext(text="Blue = +ive flouroscein (1/3/5/7/9/11)     Red = -ive PBS (2/4/6/8/10)",side=3)
if(data_type == "CV") { abline(h = 0.15, lty=2) }
title(main=main_title, xlab="", ylab=y_label, font.lab = 2, cex.lab=1.4, cex.main=1.5)
axis(1, at=1:length(dates), lab=dates, las=2)
axis(2)
box()

# Define the appearance of each line
formatting = data.frame(c(1,2,3,4,5,6,7,8,9,10,11,12),
						rep(c("blue3", "red3"), 6),
						c(1,1,3,3,1,1,3,3,1,1,3,3),
						c(1,1,1,1,17,17,17,17,NA,NA,NA,NA),
						stringsAsFactors=FALSE)
names(formatting) = c("collumn", "color", "lty", "pch")

# Plot the lines, and store the formatting
pch_list = c()
lty_list = c()
col_list = c()
for (col in colls) {
	lines(data$statistic[data$group==col],type="o",pch=formatting[col,]$pch, lty=formatting[col,]$lty, col=formatting[col,]$color)
	pch_list = c(pch_list, formatting[col,]$pch)
	lty_list = c(lty_list, formatting[col,]$lty)
	col_list = c(col_list, formatting[col,]$color)
	}

print(colls)

# Display the legend
legend("topleft", legend=colls, cex=0.8, pch=pch_list, lty=lty_list, box.col = "white",bg = "white", col=col_list)
dev.off()
