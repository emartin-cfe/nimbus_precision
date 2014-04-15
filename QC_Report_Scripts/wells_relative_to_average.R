#!/usr/bin/env Rscript

# INPUT: A 3-column CSV (date, group, statistic),
#        The group is the well
#        The statistic is Avg(Well)/Avg(Plate)

DATE_FORMAT = "%d-%b-%y"
DEFAULT_COLOR = "#55555566"

STD_DEV = 0.15

args<-commandArgs(TRUE)
syntax_message = "Correct syntax: ./well.R <CSV> <stupid_filler> <png_file>"
if (length(args) != 3) { stop(syntax_message) }
file_path = args[1]
ignore = args[2]
fname = args[3]

png(fname,width=12,height=8, units="in", res=150)
data <- read.csv(file=file_path,head=TRUE,sep=",")
data <- data[order(as.Date(data$date, "%d-%b-%y"),substr(data$group,1,1), as.numeric(substr(data$group,2,3))),]
dates = as.Date(unique(data$date), DATE_FORMAT)

par(mar=c(7.1,4.1,4.1,4.1))		# Ensure legends fit
par(font.lab=2) 				# Bold axis label
par(cex.lab=1.4)				# Larger axis label
plot(NA, xlim=c(1,length(dates)+0.5), ylim=c(1 - 3*STD_DEV - 0.1,1 + 3*STD_DEV + 0.1), axes=FALSE, ann=FALSE, xaxs="r")
main_title = "Triplicate average of wells with respect to plate average"
y_label="Avg(Well) / Avg(Plate)"
title(main=main_title, xlab="", ylab=y_label, font.lab = 2, cex.lab=1.4, cex.main=1.5)
axis(1, at=1:length(dates), lab=dates, las=2)
axis(2)

# Automatically label lines outside of accepted range
abline(h=1 - 1*STD_DEV, lty="dotted", lwd=1, col="grey2")
abline(h=1 - 2*STD_DEV, lty="longdash", lwd=1, col="grey2")
abline(h=1 - 3*STD_DEV, lty="longdash", lwd=2, col="grey2")
abline(h=1 + 1*STD_DEV, lty="dotted", lwd=1, col="grey2")
abline(h=1 + 2*STD_DEV, lty="longdash", lwd=1, col="grey2")
abline(h=1 + 3*STD_DEV, lty="longdash", lwd=2, col="grey2")

# Check each well in the final timepoint
legend <- data.frame(group = character(), color = character(), stringsAsFactors=FALSE)
final_timepoint_data = data[as.Date(data$date, DATE_FORMAT) == as.Date(dates[length(dates)], DATE_FORMAT),]

# But also store the well for previous timepoints
n_minus_1_timepoint = data[as.Date(data$date, DATE_FORMAT) == as.Date(dates[length(dates)-1], DATE_FORMAT),]
n_minus_2_timepoint = data[as.Date(data$date, DATE_FORMAT) == as.Date(dates[length(dates)-2], DATE_FORMAT),]
n_minus_3_timepoint = data[as.Date(data$date, DATE_FORMAT) == as.Date(dates[length(dates)-2], DATE_FORMAT),]

for (well in final_timepoint_data$group) {
	curr_data = final_timepoint_data[final_timepoint_data$group == well,]
	n_minus_1_data = n_minus_1_timepoint[n_minus_1_timepoint$group == well,]
	n_minus_2_data = n_minus_2_timepoint[n_minus_2_timepoint$group == well,]
	n_minus_3_data = n_minus_2_timepoint[n_minus_2_timepoint$group == well,]
	color_A = NULL

	# Choose special colors if WestGard rules are breached
	QC_breached = 0

	if(abs(curr_data$statistic - 1) > 3*STD_DEV) {
		QC_breached = 1
	} else if (abs(curr_data$statistic - 1) > 2*STD_DEV && abs(n_minus_1_data$statistic - 1) > 2*STD_DEV) {
		QC_breached = 1
	} else if (abs(curr_data$statistic - 1) > 1*STD_DEV && abs(n_minus_1_data$statistic - 1) > 1*STD_DEV && abs(n_minus_2_data$statistic - 1) && abs(n_minus_3_data$statistic - 1) > 1*STD_DEV) {
		QC_breached = 1
		} 

	if (QC_breached == 1) {
		color_A = sample(rainbow(48,1))
        text(length(dates)+abs(jitter(0.3,factor=80)),curr_data$statistic,labels=curr_data$group, cex=1, col=color_A)
	} else {
		color_A = DEFAULT_COLOR
	}

	# Store the well's color in a dataframe
	new_row = data.frame(group = curr_data$group, color = color_A, stringsAsFactors = FALSE)
	legend = rbind(legend, new_row)
	}

# Plot the lines grey by default, or with a color if it's interesting
for (well in unique(data$group)) {
	color_B = legend[legend$group==well,]$color
	lwd = 1.5
	if(color_B != DEFAULT_COLOR) {
		lwd = 1.75
		}
    lines(subset(data, group == well)$statistic, col=color_B, lwd=lwd)
    }
dev.off()
