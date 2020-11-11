#####################################################################
# File: MSMS.pm 
# Author: Brian Armstrong
# Modified: Sam Seaver (heavily)
#
# Comments:
#       Provides an interface for the MSMS solvent accessible surface program 
#
# Modified: 02 Oct 03

package MSMS;

use strict;
use Errno qw(EAGAIN);
use Cwd;
use PDB::Writer;

my $default_path = './dependencies/msms/';
my $job;
my ($c1,$c2);
my $xml;

my $rm=0;

sub doMSMS{
    my $self=shift;
    my $pdb=shift;
    ($job,$c1,$c2,$xml)=@_;

    get_buried_surface($pdb);
}

# Class method: get_buried_surface()
#
# arguments: the PDB object and two chain ids
#
# returns: an complex hash listing the residues determined to be in contact
#
# this function forks into two processes which perform the same 3 steps
# 1) write the chain out to a PDB file
# 2) convert that PDB file to an xyzr file using the pdb_to_xyzr script
# 3) run MSMS on the two chains (in opposite orders)
#
# between steps (2) and (3) the processes must synchronize, because both
# .xyzr files must exist before MSMS can be run. This is accomplished by
# having each process create a file called "chain_*.done" when its xyzr 
# file is complete. Each process tests for the existance of the corresponding
# .done file before running the MSMS program.
#
# the child process exits as soon as its MSMS run has completed. Once both MSMS
# runs have completed, the function parses the output files, updates the chains,
# and creates an MSMS object containing those residues which form the        
# interaction surface.   

sub get_buried_surface {
	my $pdb = shift;

	my $cf1 = $job.$c1;
	my $cf2 = $job.$c2;
	
	my $cpf1 = $cf1.$c2;
	my $cpf2 = $cf2.$c1;

	my $child;

      FORK: {
	  if ($child = fork) {
	      PDB::Writer->write('model'=>$pdb->getModel,'path'=>"$cf1.pdb",'chains'=>[$c1],'pdb'=>$pdb,'xml'=>$xml);

	      convert_to_xyzr($cf1);

	      open( DONEFILE, ">$cf1.done" ) or 
		  die "\ncouldn't create $cf1.done: $!";
	      close(DONEFILE);
	      
	      until( -e "$cf2.done" ) {}

	      my $outfile = run_msms($cf1,$cf2);
	      
	      rename( $outfile, "$cpf1.anal" ) or warn "\ncouldn't rename $outfile: $!";
	      
	      unlink( "$cf1.done" )  or warn "\ncouldn't remove $cf1.done: $!";

	      ##if we don't wait for the child to exit, bad things
	      ##(eg zombies) could happen down the road
	      waitpid( $child, 0);

	  }elsif (defined $child) {
	      PDB::Writer->write('model'=>$pdb->getModel,'path'=>"$cf2.pdb",'chains'=>[$c2],'pdb'=>$pdb,'xml'=>$xml);

	      convert_to_xyzr($cf2);

	      # creating this file will signal to the other process
	      # that we are finished writing our xyzr file, so it
	      # is safe to start running MSMS
	      open( SYNCFILE, ">$cf2.done" ) or 
		  die "\ncouldn't create $cf2.done: $!";
	      close( SYNCFILE );
	      
	      # wait for the other process to signal that it is
	      # safe to continue
	      until( -e "$cf1.done" ) {}

	      my $outfile = run_msms($cf2,$cf1);
	      
	      rename( $outfile, "$cpf2.anal" ) or warn "\ncouldn't rename $outfile: $!";
	      
	      unlink( "$cf2.done" ) or warn "\ncouldn't remove $cf1.done: $!";
	      exit;
	  }elsif ($! == EAGAIN) {
	      sleep 5;
	      redo FORK;
	  }else {
	      die "Can't fork: $!\n";
	  }
      }
	unlink( "$cf1.pdb","$cf2.pdb","$cf1.xyzr","$cf2.xyzr" ) if $rm;

	read_results ($pdb, "$cpf1.anal","$cpf2.anal");
}

# Function: convert_to_xyzr() *This is NOT a class or object method!
#
# Arguments:
#	$pdbfile: filename of the PDB file to convert
#
# Returns: a string containing the name of the new .xyzr file

sub convert_to_xyzr {
	my $file = shift;

	my $xyzr = $default_path."pdb_to_xyzr -h";

	qx "$xyzr $file.pdb > $file.xyzr";

	return "$file.xyzr";
}

# Function: run_msms() *This is NOT a class or object method!
#
# Arguments:
#	$cf1: the base for the first .xyzr file
#	$cf2: the base for the second .xyzr file
# 
# Returns: the name of the .anal file produced by MSMS, 
#	   or undef if no .anal file was created (some error with MSMS)
#
# this function will pass the files to MSMS in the same order
# that they are supplied as arguments, so the .anal file created
# will contain data for the chain represented by $cf1

sub run_msms {
	my( $cf1, $cf2 ) = @_;

	my $msms = "$default_path/buried";

	my $mslog = $job.$c1.$c2."msms.log";

	# STDERR is redirected to STDOUT because
	# MSMS will emit some random diagnostic messages.
	# Running msms now
	qx "$msms $cf1 $cf2 19 >> $mslog 2>&1";

	my $outbase = $job.substr($cf1,-1)."ct".substr($cf2,-1)."_19";
	qx "cat $outbase.log >> $mslog";
	$rm=0;
	unlink( "$outbase.vert", "$outbase.face", "$outbase.log" ) if $rm;
	$rm=0;
	return "$outbase.anal" if -e "$outbase.anal";
	return undef;
}

sub get_heavy_atom {
    my( $residue, $atom ) = @_;
    
    $atom =~ /^\d?H(\w?\d?\*?)/;
    
    my $suffix = $1;
    if($suffix =~ /\*$/){
	$suffix = substr($suffix, 0, length($suffix)-1)."\\*"; #making sure suffix has "\*"
    }
    my $heavy;
    if( defined $suffix && $suffix ne "") {
	#print STDERR "SUFFIX: \"$suffix\"\n";
	foreach my $a ($residue->atoms) {
	    if($residue->name =~ /U|T|G|C|A/ && $a =~ /O\d\*$/){next;} #skipping star oxygens
		#print STDERR "SUFFIX ATOMS: $a\n";
	    if($a =~ /$suffix$/ && $a !~ /^\d?H/) {
		$heavy = $a;
		last;
	    }
	}
    }
    else { $heavy = 'N'; }
    return $heavy;
}

# Function: read_results() *This is NOT a class or object method!
#
# this function parses the .anal files created by MSMS. It will then add
# that contact surface information to the apporpriate atoms.

sub read_results {
    my $pdb = shift;
    my @files=@_;
    my $results = {};
    my $overalls = {};
    
    my $chain;
    foreach my $file (@files) {
	$file =~ /(\w)\w\.anal/;
	$chain = $1;
	open( MSDATA, "<$file" ) or warn "\nin MSMS.pm: Couldn't open $file: $!";
	
	#first read past all the useless header info
	while( my $junk = <MSDATA> ) { last if $junk =~ /-{10}/; }
	
	#now read in the list of atoms
	while( my $atom = <MSDATA> ) {
	    last if $atom =~ /-{10}/;
	    $atom =~ s/^\s*//;
	    $pdb->contact($atom, $chain);
	}	    
	while( my $overall = <MSDATA> ){
	    last if $overall =~ /-{10}/;
	    
	    $overall =~ s/^\s*//;
	    my( $junk, $vert, $area ) = split /\s+/, $overall;
	    $overalls->{$chain}->{"total"} = $area;
	}
	while(my $junk = <MSDATA> ) { last if $junk =~ /-{10}/; }
	while( my $residue = <MSDATA> ){
	    $residue =~ s/^\s*//;
	    $pdb->residueAP($residue, $chain);
	}
	close( MSDATA );
    }
    unlink( @files ) if $rm;
}
1;
