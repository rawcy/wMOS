#!/usr/bin/perl 
use FindBin;
use lib "$FindBin::Bin/lib";
use Data::Dumper;
use XML::Simple;

require "$FindBin::Bin/conf/wMOSweb.conf";

use vars qw (%video_list @grp);

print Dumper(%video_list);
print Dumper(@grp);

foreach $video (keys %video_list){
	print "$video\n";
	print $video_list{$video}{'icon'} . "\n";
	foreach $code (@{$video_list{$video}{'code'}}){
		print $code . "\n";
	} 
}

foreach $local (@grp){
	print $local. "\n";
}

my $video_src = "video/m3u8";

$video_src =~ s/video\/m3u8/application\/vnd.apple.mpegurl/;

print $video_src