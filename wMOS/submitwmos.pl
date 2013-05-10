#!/usr/bin/perl -w

##############################################
##  Author:       Yin Chen                  ##                     
##  Contact:      yinche@cisco.com          ##
##  Data:         May 8 2013                ##
##  Project:      wMOS                      ##
##############################################

use strict;
use FileHandle;
use CGI::Carp 'fatalsToBrowser';
use File::Slurp;
use FindBin;

my $tmp = "$FindBin::Bin/tmp";
my $data_path = "$FindBin::Bin/data";

#mac address regexp
my $d = "[0-9A-Fa-f]";
my $dd = "$d$d";


my ($logfile, $wmos);
if (@ARGV == 2) {
	$logfile = $ARGV[0];
	$wmos = $ARGV[1];

} else {
	print "ERROR: no argument passed";
	exit 1;
}

print $data_path;
	
if (! -d $data_path){
    `mkdir $data_path`;
}
my $fileLOG = $tmp . "/" . $logfile . ".log";
if (-e $fileLOG) {
	my $fileCSV = $tmp . "/" . $logfile . ".csv";
	my $log = $data_path . "/" . $logfile . ".log";
	my $csv = $data_path . "/" . $logfile . ".csv";
	my $text = read_file($fileLOG);
	if ($text !~ m/wMOS Score/){
		append_file($fileLOG, "wMOS Score: $wmos");
	}	
	system("mv $fileLOG $log");
    sleep 20;
	system("mv $fileCSV $csv");
} else {
	return "Server error: no logs found on the server, please contact administrator.";
}
