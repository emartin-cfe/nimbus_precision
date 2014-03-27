#!/usr/bin/env Rscript

args<-commandArgs(TRUE)
syntax_message = "Correct syntax: ./well.R <CSV> <'Average' or 'CV'> <png_file>"
if (length(args) != 3) { stop(syntax_message) }
file_path = args[1]
data_type = args[2]
fname = args[3]

# Customize the chart labels by the data type. Also, for CV data, fix the y_scaling.
if (data_type != "Average" & data_type != "CV") { stop(syntax_message) }
if (data_type == "Average") { y_label="Average of RFU"; main_label = "Median RFU (IQR) across all wells (full plate)"; y_lim=NULL; }
if (data_type == "CV") { y_label="CV of RFU"; main_label = "Median RFU CV (IQR) across all wells (full plate)"; y_lim=c(0,0.5); }

png(fname,width=800,height=500)
mydata <- read.csv(file=file_path,head=TRUE,sep=",")
mydata <- mydata[order(mydata$date,substr(mydata$group,1,1), as.numeric(substr(mydata$group,2,3))),]
dates = as.Date(unique(mydata$date))

par(mar=c(7.1,4.1,4.1,2.1))		# Ensure legends fit
par(font.lab=2) 				# Bold axis label
par(cex.lab=1.4)				# Larger axis label

boxplot(statistic ~ date, data = mydata, ylab=y_label, ylim=y_lim, main=main_label, las=3)
if(data_type == "CV") { abline(h=0.40, lty=2) }
dev.off()
