#!/usr/bin/perl 

##############################################
##  Author:       Yin Chen                  ##                     
##  Contact:      yinche@cisco.com          ##
##  Data:         May 9 2013                ##
##  Project:      wMOS                      ##
##############################################


use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use strict;
use FileHandle;
use CGI::Carp 'fatalsToBrowser';
use Cwd;
use File::Slurp;
use vars qw (%video_list @grp);
use FindBin;

require "$FindBin::Bin/conf/wMOSweb.conf";

$ENV{PATH}="/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin";
my $email = "yinche\@cisco.com";
my $client_ip = $ENV{'REMOTE_ADDR'};
my $host = $ENV{'SERVER_NAME'};
my $clients_info;
my $info_text;
my $cur_dir = getcwd(); 
my $perl = '/usr/bin/perl';
my $ssh = '/usr/bin/ssh';
my $script_name = $0;
$script_name =~ s/$cur_dir\///;
	
my $ssh_server = "172.26.158.113";
my $ssh_user = "root";

my $serchclient = "$cur_dir/../wMOS/searchClient.pl";
my $collectData = "collectData";
my $submitwmos = "$cur_dir/../wMOS/submitwmos.pl";

my $video_name = "Eyesteelfilm-TrailerRiPARemixManifesto882-computer";

#mac address regexp
my $d = "[0-9A-Fa-f]";
my $dd = "$d$d";


print header;
print start_html(-title => "wMOS",
				 -script=> [{	-type 	=> 'text/javascript',
				 				-src	=> '/javascript/wMOS.js'	
				 			}]);
my @fields = param;
if (@fields ==0) {
	print <<EndHTML;
	<h2>wMOS Test Demo</h2>

	<p> Local IP address: $client_ip </p>

	<p> Please Click the 'start MOS' button to start the test </p>
EndHTML
	print start_form(-method=>'POST', -action=>"/cgi-bin/$script_name", -onSubmit=>"javascript:return checkMACAddress();"),"<em> Mac Address : </em>", 
		textfield( -name => 'client_mac', -id => 'mac', -default => 'FF:FF:FF:FF:FF:FF', -size => 17, -maxlength => 17),
		popup_menu( -name => 'local',-value =>\@grp, -default=> 'none'), 
		"<br>", submit(-name=>'sub_form', -value=>'Start MOS'), end_form, hr;
} elsif (param('wMOS')) {
	my $wMOS = param('wMOS');
	my $client_mac = param('client_mac');
	my $output = param('output');
	
	my $pout = `$ssh $ssh_server -l $ssh_user "kill -TERM \`ps -ef | awk '\/$collectData\.pl.*$output\$\/ {print \$2}'\`"`;
    #print "$ssh $ssh_server -l $ssh_user '$submitwmos $output $wMOS'";
	#my $copy_log = `scp $ssh_user\@$ssh_server:/wMOS/data/$output* /var/www/wMOS/.`;
	my $log_URL = "http://$host/wMOS/data";
	print <<ENDHTML;
		<p>The wMOS test has finished, test Session details is listed below </p> 
		<p>wMOS Score: $wMOS </p>
		<a href='$log_URL'>Logs</p>
ENDHTML
    
	my $submit = `$ssh $ssh_server -l $ssh_user '$submitwmos $output $wMOS'`;
} else {
	my $timestamp = time();
	my $client_mac = param('client_mac');
	my $local = param('local');
    my $cmd;
	my $output = $client_mac . "-" . $timestamp;
	$output =~ s/://g;

	print <<ENDHTML;

	<p> wMOS Testing </p>
	<body style="height:100%; display:block">

ENDHTML
	
	if( $client_mac =~ /($dd){6}|$dd(([:-])$dd){5}/ && $client_mac ne "FF:FF:FF:FF:FF:FF"){
		$cmd = "$ssh $ssh_server -l $ssh_user '$perl $serchclient $client_ip $output $client_mac $local'";		
	} else {
		$cmd = "$ssh $ssh_server -l $ssh_user '$perl $serchclient $client_ip $output $local'";		
	}
	my $ssh_log = `$cmd`;
	if ($ssh_log){
		print <<ENDHTML;
		<script type="text/javascript">
			window.onload=function(){
				document.getElementById('videolist').onchange = function() {
					var cusid_ele = document.getElementsByClassName('video');
					for (var i = 0; i < cusid_ele.length; ++i) {
						var item = cusid_ele[i];  
						item.style.display = 'none';
					}
					document.getElementById(this.value).style.display = 'block';
				};
			}
		</script>
ENDHTML
	print "<select name='videolist' id='videolist'>\n";
	foreach my $video (keys %video_list){
		print "<option selected='$video' value='$video'>$video</option>\n";
	}
	print "</select>\n";
	
	my $default = 1;
	foreach my $video (keys %video_list){
		if($default){
			print "<div id='$video' class='video' style='display: none'>\n";
			$default = 0;
		} else {
			print "<div id='$video' class='video' style='display: none'>\n";
		}
		print "<video poster='/icon/$video.$video_list{$video}{'icon'}' height='$video_list{$video}{'height'}' width='$video_list{$video}{'width'}' controls>\n";
				
		foreach my $code (@{$video_list{$video}{'code'}}){
			my $video_src = "<source src='/video/$video.$code' type='video/$code' />\n";
			
			$video_src =~ s/video\/ogv/video\/ogg/;
			$video_src =~ s/video\/m3u8/application\/vnd.apple.mpegurl/;
			
			print $video_src . "\n";
						
		} 
		print "<p class='warning'>Your browser does not support HTML5 video.</p>\n";
		print "</video>\n</p>\n</div>";
		
	}
    
   	print <<ENDHTML;
	<div id="windDown">
	The testing is underway.<br/>
	Please play and watch the video in the window, above.<br/>
	When the video ends, please enter the score for your experience in watching the video into the box below.<br/>
	Then, press the button to end the test.<br/>
	<table border="1">
	  <tr>
	    <td colspan="3">Scoring Chart</td>
	  </tr>
	  <tr>
	    <td>Score</td><td>Quality</td><td>Impairment</td>
	  </tr>
	  <tr>
	    <td>5</td><td>Excellent</td><td>Imperceptible</td>
	  </tr>
	  <tr>
	    <td>4</td><td>Good</td><td>Perceptible but not annoying</td>
	  </tr>
	  <tr>
	    <td>3</td><td>Fair</td><td>Slightly annoying</td>
	  </tr>
	  <tr>
	    <td>2</td><td>Poor</td><td>Annoying</td>
	  </tr>
	  <tr>
	    <td>1</td><td>Bad</td><td>Very annoying</td>
	  </tr>
	</table>
      </div>
ENDHTML
      		print start_form(-method=>'POST', -action=>"/cgi-bin/$script_name"), "Wi-Fi Quality Score: <input type='text' name='wMOS' style='background-color:#addfff' value='' size='4'/>", hidden('client_mac', $client_mac),  hidden('output', $output), submit(-name=>'sub_form', -value=>'Submit'), end_form, hr;
	} else {
		print <<EndHTML;
	<h2>wMOS Test Demo</h2>
	<p>Unable to find user on listed WLCs</p>
    <p>Check the MAC address entered was correct, $client_mac </p>
	<p>Please contact Administrator if still have problem</p>
EndHTML
	}
}
print end_html;
