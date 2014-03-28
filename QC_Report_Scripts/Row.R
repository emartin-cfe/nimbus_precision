#!/usr/bin/env Rscript

syntax_error = "Correct syntax: ./row.R <CSV> <'Average' or 'CV' or 'Paired_Ratio'> <output_png>"
args<-commandArgs(TRUE)
if (length(args) != 3) { stop(syntax_error) }
file_path = args[1]													# RFU Avg or CV data for NIMBUS
data_type = args[2]
fname = args[3]

data <- read.csv(file=file_path,head=TRUE,sep=",")					# Contains a date, well, and statistic
data <- data[order(data$date,as.numeric(substr(data$group,5,6))),]	# Sort by date, well
dates = as.Date(unique(data$date))

gamut=c()
if(data_type != "Average" && data_type != "CV" && data_type != "Paired_Ratio") { stop(syntax_error) }

if(data_type == "Average") {
	rows = c('A','B','C','D','E','F','G','H'); gamut = c("blue3", "red3");
	main_title = "RFU avg by row over time"; y_label = "RFU Average"; 
	log_scale="y"; y_lim=c(10,max(data$statistic));
	}
if(data_type == "CV") {
	rows = c('A','C','E','G'); gamut = c("blue3", "blue3");
	main_title = "Median RFU CV by row over time"; y_label = "Median RFU CV";
	log_scale=""; y_lim=c(0,1);
	}
if(data_type == "Paired_Ratio") {
	rows = c('A','C','E','G'); gamut = c("blue3", "blue3");
	main_title = "Dynamic range for avg RFU across rows"; y_label = "Neg Avg RFU / Pos Avg RFU";
	log_scale=""; y_lim=c(0,0.1);
	}

png(fname,width=800,height=500)
par(mar=c(6, 5, 4, 1))
plot(NA, xlim=c(1,length(dates)), ylim=y_lim, axes=FALSE, ann=FALSE, xaxs="r", log=log_scale)
if(data_type == "Average") { mtext(text="Blue = +ive flouroscein (A/C/E/G)     Red = -ive PBS (B/D/F/H)",side=3) }
if(data_type == "CV") { abline(h = 0.15, lty=2) }
if(data_type == "Paired_Ratio") { abline(h = 0.01, lty=2) }

title(main=main_title, xlab="", ylab=y_label, font.lab = 2, cex.lab=1.4, cex.main=1.5)
axis(1, at=1:length(dates), lab=dates, las=2)
axis(2)
box()

# Define the appearance of each line
formatting = data.frame(c(1,2,3,4,5,6,7,8),
						rep(gamut, 4),
						c(1,1,3,3,1,1,3,3),
						c(1,1,1,1,17,17,17,17),
						stringsAsFactors=FALSE)
names(formatting) = c("collumn", "color", "lty", "pch")

# Plot the lines, and store the formatting
pch_list = c()
lty_list = c()
col_list = c()
i = 0
for (row in rows) {
	i = i + 1
	if (data_type == "CV") { i = i + 1 }
	lines(data$statistic[data$group==row],type="o",pch=formatting[i,]$pch, lty=formatting[i,]$lty, col=formatting[i,]$color)
	pch_list = c(pch_list, formatting[i,]$pch)
	lty_list = c(lty_list, formatting[i,]$lty)
	col_list = c(col_list, formatting[i,]$color)
	}

# Display the legend
legend("topleft", legend=rows, cex=0.8, pch=pch_list, lty=lty_list, box.col = "white", bg = "white", col=col_list)
dev.off()
