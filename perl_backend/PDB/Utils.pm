package PDB::Utils;

use strict;
use warnings;

BEGIN {
        use Exporter   ();
        our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
        $VERSION     = 1.00;
        @ISA         = qw(Exporter);
        @EXPORT      = ();
        %EXPORT_TAGS = ();   
        @EXPORT_OK = qw( &dist );
}

sub dist{
    my ($x1, $x2, $y1, $y2, $z1, $z2)=@_;
                                                                                                                                                             
    return sqrt ( ($x1 - $x2)**2 +
                  ($y1 - $y2)**2 +
                  ($z1 - $z2)**2 );
}
1;
