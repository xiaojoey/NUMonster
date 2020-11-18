#####################################################################
# File: REDUCE.pm 
# Author: Sam Seaver
#
# Comments:
#       Provides an interface for REDUCE
#
# Modified: 12 Nov 20

package REDUCE;

my $default_path = './dependencies/reduce';

sub run{
    my $self=shift;
    my $pdb=shift;
    my $log=shift;

    # STDERR is redirected to STDOUT
    # Running haad now
    qx "$default_path -BUILD -OLDpdb ${pdb} > ${pdb}.new 2>${log}";
}
1;
