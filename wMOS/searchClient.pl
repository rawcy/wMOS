#!/usr/bin/perl -w

##############################################
##  Author:       Yin Chen                  ##                     
##  Contact:      yinche@cisco.com          ##
##  Data:         May 8 2013                ##
##  Project:      wMOS                      ##
##############################################


use vars qw (%wlc_grp);

use strict;
use warnings;
use Net::SNMP;
use threads;
use threads::shared;
use Thread::Semaphore;
use XML::Simple;
use FindBin;
use lib "$FindBin::Bin/lib";
use OIDS;
use Data::Dumper;

require "$FindBin::Bin/common_snmp.pl";

BEGIN { our $start_run = time(); }


my ($output, $clientIP, $clientMAC, $local, $ERR);
if (@ARGV >= 2) {
	$clientIP = $ARGV[0];
	$output = $ARGV[1];
	if (@ARGV >= 3) {
		$clientMAC = $ARGV[2];
	}
	if (@ARGV >= 4) {
		$local = $ARGV[3];
	}
} else {
	print "ERROR: no argument passed";
	exit 1;
}

if (! -r "$FindBin::Bin/conf/wMOS.conf") {
     print "ERROR: wMOS.conf is not readable\n";
     exit 2;
}
require "$FindBin::Bin/conf/wMOS.conf";

# global variables
my $perl = '/usr/bin/perl';
my $thread_die = 0;
my $maxThreads = 15;
share($thread_die);


my (@threads, $WARN);

my $clientMAC_dec = mac_hex_decimal($clientMAC);
#mac_hex_decimal($client_mac_hex);
my $threadsThreshold = Thread::Semaphore->new($maxThreads);
foreach my $grp (keys %wlc_grp){
    last if $thread_die == 1;
	if ($grp eq $local || $local eq "unknown"){
		foreach my $wlc (@{$wlc_grp{$grp}{'host'}}){
			$threadsThreshold->down;
			my $t = threads->new(\&search_client, $wlc, $wlc_grp{$grp}{'community'}, $clientIP, $clientMAC_dec);
			$t->join();
			push(@threads,$t);
		}
	}	
}

print $thread_die;

sub search_client {
	my ($host, $community, $client_ip, $clientMAC_dec) = @_;
	
	my ($client_mac_dec, $ap_mac_dec, $ap_ip, $ap_slot_id, $client_ch);
	# create SNMP session
	if ($thread_die == 1) { 
        $threadsThreshold->up;
        return; 
    } # kill the threads;
	
	my ($error, $session) = snmp_connect($host, $community);
	if (!$session) {
		print "ERROR:$error";
        $threadsThreshold->up;
        return;	    
	} else {
        my $client_status;
		if (!$clientMAC_dec){ # search the client MAC by IP in WLC
			my $client_ip = $session->get_table(-baseoid => $OID_grp_bsnMobileStationIpAddress);
			foreach my $oid (keys %$client_ip){
					if($$client_ip{$oid} == $client_ip){
						$client_mac_dec = $oid;
						$client_mac_dec =~ s/$OID_grp_bsnMobileStationIpAddress\.//;
#						$client_mac_hex = mac_hex_decimal($client_mac_dec);				
						last;
					}
			}
			undef $client_ip; # free memory
		} else {
            $client_status = $session->get_request(-varbindlist => ["$OID_grp_bsnMobileStationStatus.$clientMAC_dec"]);
			if ($$client_status{"$OID_grp_bsnMobileStationStatus.$clientMAC_dec"} !~ /noSuchInstance/) {
				$client_mac_dec = $clientMAC_dec;
#				$client_mac_hex = mac_hex_decimal($client_mac_dec);
			}
		}
		if ($client_mac_dec){
			my $client_status = $session->get_request(-varbindlist => ["$OID_grp_bsnMobileStationStatus.$client_mac_dec"] );
			if ($$client_status{"$OID_grp_bsnMobileStationStatus.$client_mac_dec"} == 3){
				my $client_ap_info = $session->get_request(-varbindlist => [ "$OID_grp_bsnMobileStationAPMacAddr.$client_mac_dec", "$OID_grp_bsnMobileStationAPIfSlotId.$client_mac_dec" ] );
				$ap_mac_dec = mac_hex_decimal(format_mac_hex($$client_ap_info{"$OID_grp_bsnMobileStationAPMacAddr.$client_mac_dec"}));
				$ap_slot_id = $$client_ap_info{"$OID_grp_bsnMobileStationAPIfSlotId.$client_mac_dec"};
				$client_ap_info = $session->get_request(-varbindlist => [ "$OID_grp_bsnApIpAddress.$ap_mac_dec", "$OID_grp_bsnAPIfPhyChannelNumber.$ap_mac_dec.$ap_slot_id" ] );
				$ap_ip = $$client_ap_info{"$OID_grp_bsnApIpAddress.$ap_mac_dec"};
				$client_ch = $$client_ap_info{"$OID_grp_bsnAPIfPhyChannelNumber.$ap_mac_dec.$ap_slot_id"};
				$thread_die = 1;
				system("$perl $FindBin::Bin/collectData.pl $host $community $client_ip $client_mac_dec $ap_mac_dec $ap_ip $ap_slot_id $client_ch $output &>/dev/null &");				
			}
		}
	}
	$threadsThreshold->up;
}
