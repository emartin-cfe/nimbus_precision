#!/usr/bin/perl -w

use strict;
use File::Basename;

# Give an HTTP header
use CGI;
my $q = new CGI;
print $q->header;

my $perl = "/usr/bin/perl";
my $R = "/usr/bin/env Rscript";
my $root = "/var/www/cgi-bin";
my $web_server = "/var/www/html/nimbus_precision/images";

# Clear out the web server image
system("rm $web_server/*.png");

foreach my $template (('Well', 'Column', 'Row')) {
	foreach my $statistic (('Average', 'CV')) {

		# Generate the csv from the database
		my $csv = "$root/" . $template . "_" . $statistic . ".csv";
		system("$perl $root/QC_Report_Scripts/GET_NIMBUS_RFU.pl $template $statistic > $csv");

		# Generate the png
		my $png = $csv;
		$png =~ s/csv$/png/;
		my $R_script = "$root/QC_Report_Scripts/$template.R";
		system("$R $R_script $csv $statistic $png > /dev/null");

		# Move the png files to the webserver + delete the csv
		rename($png, $web_server . "/" . basename($png));
		unlink($csv);
		}
	}

# Forward web browser to a webpage containing the graphs
print '<html><head><meta http-equiv="refresh" content="0; url=http://192.168.69.214/nimbus_precision/" /></head></html>';
