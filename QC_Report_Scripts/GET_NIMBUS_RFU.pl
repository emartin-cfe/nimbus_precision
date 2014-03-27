#!/usr/bin/perl -w

# SYNOPSIS:	Generate summary statistics to visualize precision testing of the NIMBUS robotic pipetter.
# DETAILS:	Script treats multiple results from the same date with the same protocol as replicates.

use strict;
my $syntax_description = "Usage: $0 <'Column', 'Row', or 'Well'> <'Average' or 'CV'>\n";
if (scalar(@ARGV) != 2) { die $syntax_description; }

my ($statistic, $constraint) = ("", "");
if ($ARGV[1] eq "Average") { $statistic = "ROUND(AVG(RFU),0)"; }
elsif ($ARGV[1] eq "CV") {
	$statistic = "ROUND((STDDEV(RFU)/AVG(RFU)),4)";											# Do not calculate CV on zero values
	#if($ARGV[0] eq "Column") { $constraint = "AND MOD(CAST(substr(well,2,2) AS INT),2) = 1"; }	# Ignore cols 2/4/6/8/10/12
	#elsif($ARGV[0] eq "Row") { $constraint = "AND REGEXP_LIKE(substr(well,1,1), '^[ACEG]')"; }	# Ignore rows B/D/F/H
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

use DBI;
require "/var/www/cgi-bin/QC_Report_Scripts/setup_oracle_authentication.pl";
my ($env_oracle_home, $host, $port, $sid, $user, $password) = activateOracle();
my $db=DBI->connect("dbi:Oracle:host=$host;sid=$sid;port=$port", $user, $password);
my $sth = $db->prepare($query);	$sth->execute();

print "date,group,statistic\n";
while (my @row = $sth->fetchrow_array()) {
	print join( ',', @row) . "\n";
	}
