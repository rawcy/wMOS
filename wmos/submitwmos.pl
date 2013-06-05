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

use vars qw ($sleep_time $tmp $data_path);
require "$FindBin::Bin/conf/wmos.conf";

#mac address regexp
my $d = "[0-9A-Fa-f]";
my $dd = "$d$d";


my ($logfile, $wmosscore);
if (@ARGV == 2) {
	$logfile = $ARGV[0];
	$wmosscore = $ARGV[1];

} else {
	print "ERROR: no argument passed";
	exit 1;
}

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
		append_file($fileLOG, "wMOS Score: $wmosscore");
	}	
	system("mv $fileLOG $log");
    sleep $sleep_time;
	system("mv $fileCSV $csv");
} else {
	return "Server error: no logs found on the server, please contact administrator.";
}
