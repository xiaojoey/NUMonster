#####################################################################
# File: HAAD.pm 
# Author: Sam Seaver
#
# Comments:
#       Provides an interface for HAAD
#
# Modified: 01 Jan 20

package HAAD;

use strict;
use Errno qw(EAGAIN);

use PDB::Writer;

my $default_path = '/home/monster/execs/msms/';
my $job;
my ($c1,$c2);
my $xml;

my $rm=0;

sub run{
    my $self=shift;
    my $pdb=shift;
    ($job,$c1,$c2,$xml)=@_;
    get_buried_surface($pdb);
}

sub run_msms {
	my( $cf1, $cf2 ) = @_;

	my $msms = "$default_path/buried";

	my $mslog = $job.$c1.$c2."msms.log";

	# STDERR is redirected to STDOUT because
	# MSMS will emit some random diagnostic messages.
	# Running msms now
	qx "$msms $cf1.xyzr $cf2.xyzr 19 >$mslog 2>&1";

	my $outbase = $job.substr($cf1,-1)."ct".substr($cf2,-1)."_19";
	qx "cat $outbase.log >> $mslog";
	$rm=1;
	unlink( "$outbase.vert", "$outbase.face", "$outbase.log" ) if $rm;
	$rm=0;
	return "$outbase.anal" if -e "$outbase.anal";
	return undef;
}
1;
