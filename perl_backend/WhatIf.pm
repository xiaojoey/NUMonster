package WhatIf;

use strict;
use File::Basename;

sub doWhatif{
    my $self = shift;
    my $file = shift;

    my ($name, $path, $suff) = fileparse($file, '\.pdb');
    $name = substr($name, -1);
    $name = '' if $name eq 'i'; #no conformations if 'i'
    my $log = $path."wi".$name.".log";
    my $out = $path."out".$name.$suff;
    my $wi_startup = "STARTUP.FIL";

    open(WHATIF, "> $wi_startup" ) or die "\ncouldn't redirect WHATIF to $wi_startup: $! ";
    print WHATIF "%GETMOL $file mol\n\n"; #loads of models
    print WHATIF "DOLOG $log\n\n"; #extra new line to quit text
    print WHATIF "%SETWIF 1012 0\n"; #Forces Whatif to override small inconsistencies
    print WHATIF "%SETWIF 142 0\n"; #PDB naming 4-character atom names
    print WHATIF "%SETWIF 196 1\n"; #Force terminal H names
    print WHATIF "%SETWIF 1426 2\n"; #Force OXT atom names
    print WHATIF "%SETWIF 339 1\n"; #optimised H addition
    print WHATIF "%ADDHYD\nTOT 0\nY\nY\nN\n"; #Y for possible confirmation, and Y,N for possible abusive water pairs
    #print WHATIF "%NAMCHK\n";
    print WHATIF "%ROUNDC\n";
    print WHATIF "NOLOG\n";
    print WHATIF "%MAKMOL /home/monster/pdb/template.pdb $out\n";
    print WHATIF "TOT 0\n\n";
    print WHATIF "FULLST\n";
    print WHATIF "Y\n";
    #All preceding 'N's are in case of seg faults, forces whatif to do all stack dumps blah blah(hopefully)
    print WHATIF "N\nN\nN\nN\nFULLST\nY\nN\nN\nN\nN\nN\nN\nN\nN\nN\nFULLST\nY\nN\nN\nN\nN\nN\nN\nN\nN\nN\nN\nN\n";
    close WHATIF;
    
    qx "/home/monster/execs/whatif";

    #my @errors;
    #open(LOG, "< $log") or warn "\ncouldn't read LOG from $log: $! ";
    #while(<LOG>){
    #if( $_ =~  /^\s+\d+\s+(\w{3})\s+\(\s+(\d+)\s+\)\s(.)/ ) {
    #push @errors, "$3$2$1";#$4";
    #}
    #}
    #close(LOG);
    #foreach(@errors){
    #print $_."\n";
    #}

    unlink $path."pdbout.txt", $path."pdbout.tex", $path."ALTERR.LOG", $path.$wi_startup;

    return $out;
}
1;
