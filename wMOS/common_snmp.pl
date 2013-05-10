# Common SNMP related procedures

##############################################
##  Author:       Yin Chen                  ##                     
##  Contact:      yinche@cisco.com          ##
##  Data:         Oct 24 2012               ##
##  Project:      wMOS                      ##
##############################################

use Net::SNMP;
use Net::Ping;
#use strict;
#use warnings;
##Procedure Header
# Name: snmp_connect
# Description:
#   Call Net::SNMP->session
# Input:
#   $hostname      IP or hostname
#   $community     Community string
# Return Values:
#   $session        A reference to the Net::SNMP object
#   $error          The error string if a connection could not be established
sub snmp_connect {
    my ($hostname, $community) = @_;

	 my $p = Net::Ping->new();
	 if ($p->ping($hostname)){
		 return ("the $hostname is not reachable")
	 }

    my ($session, $error) = Net::SNMP->session(
                               -hostname      => $hostname,
                               -version       => "snmpv2c",
                               -community     => $community,
                               -timeout       => "2",
                            );
    if (!$session) {
        return ($error);
    }
    # Increase the size of the buffer coz some queries were failing (default 1472)
    $session->max_msg_size(1472*5);

	#Get the linux standard timestamp
    my @param_arr = ('-timeticks' => 0);
    $session->translate(\@param_arr);

    return ("", $session);
} # of snmp_connect()

##Procedure Header
# Name: snmp_get_table
# Description:
#     Do a snmptranslate and then a snmpwalk of the resulting OID
# Input:
#     $session: A connected NET::SNMP object
#     $mib_object: The symbolic MIB string to be walked
#     $mib_info:     A reference to a hash of saved MIB strings=>numeric oid
#                    associations. If its null, snmptranslate will run
#                    snmptranslate CLI to get the association (slow)
# Return Values:
#  $oid: The oid that snmptranslate translated to.
sub snmp_get_table {
   my ($session, $mib_object, $mib_info) = @_;
   my ($err, $oid) = snmptranslate ($mib_object, $mib_info);
   return ($err) if ($err);
   # Got the OID now, query it
   my $result = $session->get_table (-baseoid => $oid);
   #print Dumper ($result);
   return ($session->error(), $result, $oid);
}

sub snmp_get {
    my ($session, $oids, $mib_info) = @_;
    my @string_oid_arr = split (",", $oids);
    #my $error = "";
    my @numeric_oid_arr;
    my %snmp_get_result;
    for my $string_oid (@string_oid_arr) {
        my ($error, $numeric_oid) = snmptranslate ($string_oid, $mib_info);
        return $error if ($error);
        push (@numeric_oid_arr, $numeric_oid);
    }
    my $result = $session->get_request (-varbindlist => \@numeric_oid_arr);
    return ($session->error()) if ($session->error());
    for (my $i=0; $i<@numeric_oid_arr; $i++) {
        $snmp_get_result{$string_oid_arr[$i]} = $$result{$numeric_oid_arr[$i]};
    }
    return ("", \%snmp_get_result);
} # of snmp_get()

##Procedure Header
# Name: snmptranslate()
# Description:
#     Try to convert a mib object into an OID
#     If its a numeric dotted notation, use itself
#     Else see if an entry for it exists in conf.pl mib_objects
#    Else use snmptranslate CLI (slow)

sub snmptranslate {
   my ($mib_object, $mib_info) = @_;

   #debug (3, "snmptranslate() called with mib_object [$mib_object] mib_info [$mib_info].");
   my $oid = "";
   if ($mib_object =~ /^\.?1/) {
      #its a numeric oid so use as is
      $oid = $mib_object;
   } else {
      # Its not a numeric OID so try to tranlate it using info from conf file
      $oid = $$mib_info{$mib_object} if ($mib_info);
      if ($oid eq "") {
         print STDERR ("Warning: Using snmptranslate.sh for [$mib_object].... not good.\n");
         debug (2, "Warning: Using snmptranslate.sh for [$mib_object].... not good.\n");
         $oid = `snmptranslate -On -IR $mib_object 2> /dev/null`;
         $oid =~ s/\n$//;
         if ($oid eq "") {
            # Try loading all MIBS and retry
            print STDERR ("Warning: Trying snmptranslate.sh with MIBS=ALL (Slow!).\n");
            $oid = `snmptranslate -m ALL -M ../mibs -On -IR $mib_object`;
            $oid =~ s/\n$//;
            if ($oid eq "" ) {
               my $err = "Error: Cannot get oid for $mib_object.";
               print STDERR ("$err\n");
               return ($err);
            }
         }
      } # of oid ""
   } # of mib_object ! numeric
   $$mib_info{$mib_object} = $oid if ($mib_info);
   #debug (3, "snmptranslate() returning [$oid]");
   return ( "", $oid);
}

##Procedure Header
# Name:
#        format_mac_decimal
# Description:
#        Converts a mac address in to a decimal number
# Input:
#        $mac: MAC address
# Output:
#      Returns a string representation of a MAC address

sub format_mac_decimal {
   my ($mac) = @_;
   $mac =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/;
   return (sprintf ("%02X:%02X:%02X:%02X:%02X:%02X", $1,$2,$3,$4,$5,$6));
}

##Procedure Header
# Name:
#        format_mac_hex
# Description:
#        Converts a physical mac address in to a hexadecimal number
#        representation
# Input:
#        $mac: MAC address
# Output:
#      Returns a string representation of a MAC address
sub format_mac_hex {
   my ($mac) = @_;
   $mac = uc ($mac);
   $mac =~ m/0X(..)(..)(..)(..)(..)(..)/;
   return ("$1:$2:$3:$4:$5:$6");
}

sub mac_hex_decimal{
   my ($mac) = @_;
    
    $mac =~ /([0-9A-Fa-f]{2})[\:|\-]([0-9A-Fa-f]{2})[\:|\-]([0-9A-Fa-f]{2})[\:|\-]([0-9A-Fa-f]{2})[\:|\-]([0-9A-Fa-f]{2})[\:|\-]([0-9A-Fa-f]{2})/;
   return (sprintf ("%d.%d.%d.%d.%d.%d", hex($1),hex($2),hex($3),hex($4),hex($5),hex($6)));
}

1;
