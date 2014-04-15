#!/usr/bin/perl -w

# SYNOPSIS:	Generate summary statistics to visualize precision testing of the NIMBUS robotic pipetter.
# DETAILS:	Script treats multiple results from the same date with the same protocol as replicates.

use strict;
my $syntax_description = "Usage: $0 <'Column', 'Row', or 'Well'> <'Average' or 'CV' or 'Paired_Ratio' or 'Plate_Normalized'>\n";
if (scalar(@ARGV) != 2) { die $syntax_description; }

use DBI;
require "/var/www/cgi-bin/QC_Report_Scripts/setup_oracle_authentication.pl";
#require "setup_oracle_authentication.pl";
my ($env_oracle_home, $host, $port, $sid, $user, $password) = activateOracle();
my $db=DBI->connect("dbi:Oracle:host=$host;sid=$sid;port=$port", $user, $password);

if(($ARGV[0] eq 'Well') && ($ARGV[1] eq 'Plate_Normalized')) {

	my $query = "SELECT A.RUNDATE, WELL, well_average/plate_average normalized_rfu " .
				"FROM (" .
					"SELECT RUNDATE, AVG(RFU) plate_average " .
					"FROM specimen.lab_pcr_quant " .
					"WHERE protocol = 'NIMBUS_Precision_DTX880_Fluor_FI_Top_96well_FullPlate' " .
					"GROUP BY RUNDATE) A " .
				"JOIN ( " .
					"SELECT RUNDATE, WELL, AVG(RFU) well_average FROM specimen.lab_pcr_quant " .
					"WHERE protocol = 'NIMBUS_Precision_DTX880_Fluor_FI_Top_96well_FullPlate' " .
					"GROUP BY RUNDATE, WELL " .
					"ORDER BY rundate, substr(well,1,1), CAST(substr(well,2,2) AS INT) ) B " .
				"ON A.RUNDATE = B.RUNDATE";

	my $sth = $db->prepare($query);
	$sth->execute();
	print "date,group,statistic\n";
	while (my @row = $sth->fetchrow_array()) {
		my ($date, $well, $statistic) = @row;
		print "$date,$well,$statistic\n";
		}   

	# Get the avg for a timepoint
	exit 1;
	}


# Get the average of adjacent positive columns/rows, and divide them to get the dynamic range
if ($ARGV[1] eq 'Paired_Ratio') {
	my ($location, $order_by, $protocol, $constraint_positive, $constraint_negative);
	my $statistic = "ROUND(AVG(RFU),0)";

	if ($ARGV[0] eq 'Row') {
		$location = "substr(well,1,1)";
		$order_by = "coordinate";
		$protocol = "NIMBUS_Precision_DTX880_Fluor_FI_Top_96well_byRow";
		$constraint_positive = " REGEXP_LIKE(substr(well,1,1), '^[ACEG]')";
		$constraint_negative = " REGEXP_LIKE(substr(well,1,1), '^[BDFH]')";
		}
	elsif ($ARGV[0] eq 'Column') {
		$location = "substr(well,2,2)";
		$order_by = "CAST(coordinate AS INT)";
		$protocol = "NIMBUS_Precision_DTX880_Fluor_FI_Top_96well_ByColumns";
		$constraint_positive = " MOD(CAST(substr(well,2,2) AS INT),2) = 1";		# Cols 1/3/5/7/9/11
		$constraint_negative = " MOD(CAST(substr(well,2,2) AS INT),2) = 0";		# Cols 2/4/6/8/10/12
		}
	else { die 'Must specify row or column when using invoking Paired_Ratio'; }

	my $format_string = "SELECT TO_CHAR(rundate, 'YYYY-MM-DD'), %s coordinate, %s FROM specimen.lab_pcr_quant " .
 						"WHERE protocol = '%s' AND (SYSDATE-RUNDATE) < 365 AND %s " .
						"GROUP BY rundate, %s ORDER BY rundate, %s";

	my $query_pos = sprintf($format_string, $location, $statistic, $protocol, $constraint_positive, $location, $order_by);
	my $sth_pos = $db->prepare($query_pos); $sth_pos->execute();

	my $query_neg = sprintf($format_string, $location, $statistic, $protocol, $constraint_negative, $location, $order_by);
	my $sth_neg = $db->prepare($query_neg); $sth_neg->execute();

	print "date,group,statistic\n";
	while (my @row_pos = $sth_pos->fetchrow_array()) {
		my @row_neg = $sth_neg->fetchrow_array();
		my ($date, $location, $pos, $neg) = ($row_pos[0], $row_pos[1], $row_pos[2], $row_neg[2]);
		my $ratio = sprintf("%.4f", $neg / $pos);
		print "$date,$location,$ratio\n";
		}
	exit 1;
	}



my ($statistic, $constraint) = ("", "");
if ($ARGV[1] eq "Average") { $statistic = "ROUND(AVG(RFU),0)"; }
elsif ($ARGV[1] eq "CV") {
	$statistic = "ROUND((STDDEV(RFU)/AVG(RFU)),4)";												# Do not calculate CV on zero values
	if($ARGV[0] eq "Column") { $constraint = "AND MOD(CAST(substr(well,2,2) AS INT),2) = 1"; }	# Ignore cols 2/4/6/8/10/12
	elsif($ARGV[0] eq "Row") { $constraint = "AND REGEXP_LIKE(substr(well,1,1), '^[ACEG]')"; }	# Ignore rows B/D/F/H
	}
else { die $syntax_description; }

my $query = "";
if ($ARGV[0] eq "Column") {	$query =	"SELECT TO_CHAR(rundate, 'YYYY-MM-DD'), substr(well,2,2) well_column, $statistic " .
										"FROM specimen.lab_pcr_quant " .
										"WHERE protocol = 'NIMBUS_Precision_DTX880_Fluor_FI_Top_96well_ByColumns' AND (SYSDATE-RUNDATE) < 365 $constraint " .
										"GROUP BY rundate, substr(well,2,2) ORDER BY rundate, CAST(well_column AS INT)"; }

elsif($ARGV[0] eq "Row") {	$query =	"SELECT TO_CHAR(rundate, 'YYYY-MM-DD'), substr(well,1,1) well_row, $statistic " .
										"FROM specimen.lab_pcr_quant " .
										"WHERE protocol = 'NIMBUS_Precision_DTX880_Fluor_FI_Top_96well_byRow' AND (SYSDATE-RUNDATE) < 365 $constraint " .
										"GROUP BY rundate, substr(well,1,1) ORDER BY rundate, well_row"; }

elsif($ARGV[0] eq "Well") {	$query =	"SELECT TO_CHAR(rundate, 'YYYY-MM-DD'), well, $statistic " .
										"FROM specimen.lab_pcr_quant " .
										"WHERE protocol = 'NIMBUS_Precision_DTX880_Fluor_FI_Top_96well_FullPlate' AND (SYSDATE-RUNDATE) < 365 " .
										"GROUP BY rundate, well ORDER BY rundate, substr(well,1,1), CAST(substr(well,2,2) AS INT)"; }

else { die $syntax_description; }

my $sth = $db->prepare($query);	$sth->execute();

print "date,group,statistic\n";
while (my @row = $sth->fetchrow_array()) {
	print join( ',', @row) . "\n";
	}
