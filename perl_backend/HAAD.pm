#####################################################################
# File: HAAD.pm 
# Author: Sam Seaver
#
# Comments:
#       Provides an interface for HAAD
#
# Modified: 01 Jan 20

package HAAD;

my $default_path = './dependencies/haad/haad';

sub run{
    my $self=shift;
    my $pdb=shift;
    my $log=shift;

    # STDERR is redirected to STDOUT
    # Running haad now
    qx "$default_path $pdb >$log 2>&1";
}
1;
