package PDB::Writer;

use strict;
use warnings;

#Spacers for printing out
#m=1, t=3, s=6    
my $ms = " ";
my $ts = "   ";
my $ss = "      ";
my $protons='';

BEGIN {
        use Exporter   ();
        our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
        $VERSION     = 1.00;
        @ISA         = qw(Exporter);
        @EXPORT      = ();
        %EXPORT_TAGS = ();   
        @EXPORT_OK = qw( &pad_left &pad_right &numberFormat );
}

sub write{
    my $self=shift;
    my %args = @_;

    my $pdb = $args{'pdb'};

    my @models = $args{'models'};
    $protons = $args{'protons'};

    #print "Writing to ".$args{'path'}."\n";
    open(FH, "> ".$args{'path'}); 
    #print "Writing to ".$args{'path'}."\n";
#Find last residues for termination 
#hetatms excluded by not being added to $pdb->residues
#

    my($first,@terRes);
    if($args{'xml'}){
	my @chs = $args{'xml'}->chains;
	for(my $i=0;$i<scalar @chs;$i++){
	    $terRes[$i]=$chs[$i].$args{'xml'}->end($chs[$i]);
	}
    }else{
	foreach my $ref (sort{substr($a,0,1) cmp substr($b,0,1) 
				  || 
				  substr($a,1) <=> substr($b,1) 
			      } $pdb->residues){
	    if(@{$args{'chains'}}[0] && substr($ref,0,1) eq @{$args{'chains'}}[0] ||
	       @{$args{'chains'}}[1] && substr($ref,0,1) eq @{$args{'chains'}}[1]){
		#initialises ter1
		$terRes[0]=$ref unless $first;
		$first=1;
		
		#exchanges ter between chains
		$terRes[0]=$ref unless substr($ref,0,1) ne substr($terRes[0],0,1);
		$terRes[1]=$ref if substr($ref,0,1) ne substr($terRes[0],0,1);
	    }
	}
    }

    my($last,%terAtoms);
    #find the last atoms for the ter    
    for(my $i=0; $i<scalar @terRes; $i++){
	foreach my $ref ($pdb->atomsR($terRes[$i])){
	    $last=$pdb->atomNumber($ref) if $pdb->atom($ref);
	    $last=$pdb->atomNumber($ref) if $pdb->proton($ref);
	}
	$terAtoms{substr($terRes[$i],0,1)}{$last}=1;
    }

    #iterate for printing

    foreach my $m(@models){
	$pdb->setModel($m);
	#print FH $self->model($m) if $args{'models'}>1;
	foreach my $ch ( sort @{$args{'chains'}} ){
	    foreach my $res ($pdb->chainResidues($ch)){
		foreach my $ref (sort { $a <=> $b } $pdb->atomsR($res)){
		    print FH $self->line($pdb->atom($ref), $ch) if $pdb->atom($ref);
		    print FH $self->line($pdb->proton($ref), $ch) if $pdb->proton($ref);
		    print FH ter($pdb->atom($ref), $ch) if $pdb->atom($ref) && $terAtoms{$ch}{$pdb->atom($ref)->atomNumber};
		    print FH ter($pdb->proton($ref), $ch) if $pdb->proton($ref) && $terAtoms{$ch}{$pdb->proton($ref)->atomNumber};
		    print FH $self->line($pdb->hetatm($ref), $ch) if $pdb->hetatm($ref);
		}
	    }
	}
	
	if($args{'water'}){
	    foreach my $ref ($pdb->water){
		print FH $self->line($pdb->water($ref));
	    }
	}
	#print FH "ENDMDL\n" if $args{'models'}>1;
    }
    close(FH);
}

sub line{
    my $self=shift;
    my $line = shift;
    my $ch = shift;
    $ch = $line->chainId unless $ch;

    my $string = type($line->type).number($line->atomNumber, 5).$ms;
    $string .= atomName($line->atomName(), $line->resName());
    #Commented out because of new method of retaining atoms
    #$string .= pdbAtomName($line->isNA, $line->atomEl, $line->atomRemote, $line->atomBranch, $line->hydNumber) if $line->proton && $protons;
    $string .= single($line->altLoc).name($line->resName,3).$ms.$ch.number($line->resNumber, 4).single($line->insCode);
    $string .= $ts.number($line->x,8).number($line->y,8).number($line->z,8).number($line->occ, 6);
    $string .= number($line->temp, 6).$ss.number($line->segId,4).name($line->el,2).name($line->charge,2);
    $string .= "\n";
    return $string;
}

sub ter{
    my $line = shift;
    my $ch = shift;

    my $string = "TER".$ts.number($line->atomNumber, 5).$ss.name($line->resName,3).$ms;
    $string .= $ch.number($line->resNumber, 4).single($line->insCode)."\n";
    return $string;
}

sub model{
    my $self=shift;
    my $number = shift;
    return "MODEL    ".pad_left($number,4)."\n";
}

sub type{
    return pad_right($_[0], 6);
}

sub number{
    return pad_left($_[0], $_[1]);
}

sub atomName{
    my $a = $_[0];
    my $temp;
    if($protons && $protons eq 'hbplus'){
        $a =~ s/7/5M/ if $a =~ /C/;
	if($_[1] eq 'LYS'){
	    $a = $2.$1 if $a =~ /^(HZ)([123])$/;
	}
	if($_[1] eq 'TYR' || $_[1] eq 'TRP'){
	    $a = $2.$1 if $a =~ /^(HB)([23])$/;
	}
	if($_[1] eq 'ASP'){
	    $a = $2.$1 if $a =~ /^([12])(HD)$/;
	}
	if($_[1] =~ /^\+?[GCTAU]$/){
	    $a =~ s/^(H\d)(\d)$/$2$1/;
	    $a =~ s/^(\d)H7$/$1H5M/;
	    #NA terminal hydrogens
	    #H5T/H3T & *HO2 unrecognised by HBplus
	    #$a = ??'H'?? if $a =~ /^H([123])T?$/;
	    #$a =~ s/^(\*)(HO2)$/$2$1/;
	}else{
	    #AA terminal hydrogens
	    $a = $1.'H' if $a =~ /^HT?([123])$/;
	}
    }elsif($protons && $protons eq 'webmol'){
	$a = 'O' if $a eq 'O\'';
    }
    if(length($a) == 1){
	$temp = pad_left($a,2);
	$a = $temp;
	$temp = pad_right($a,4);
	return $temp;
    }elsif(length($a) == 2){
	if(substr($a,0,1) =~ /\d/){
	    $temp = pad_right($a,4);
	}else{
	    $temp = pad_left($a,3);
	    $a = $temp;
	    $temp = pad_right($a,4);
	}
	return $temp;
    }elsif(length($a) == 3){
	if(substr($a,0,1) =~ /\d/){
	    $temp = pad_right($a,4);
	}else{
	    $temp = pad_left($a,4);
	}
	return $temp;
    }elsif(length($a) == 4){
	return $a;
    }
}

sub pdbAtomName{
    my ($na,$el,$re,$br,$hy) = @_;
    if($protons){
	$re =~ s/\'/\*/ if $re;
	$br =~ s/\'/\*/ if $br;
	$hy =~ s/\'/\*/ if $hy;
	if($re eq '7' && $na){
	    $re = 5;
	    $br = 'M';
	}
	if($re =~ /2|5/ && $br eq '*' && $na){
	    $hy = 1;
	}elsif($hy eq '*' && $na && $re ne 'O'){
	    $hy = 2;
	}
    }
    return single($hy).single($el).single($re).single($br);
}

sub name{
    return pad_left($_[0], $_[1]);
}

sub single{
    return pad_right($_[0], 1);
}

sub pad_left {
    my ($item, $size, $padding) = @_;	
    my $newItem = $item;
    $padding = ' ' unless defined $padding;
    
    while( length $newItem < $size ) {
	$newItem = "$padding$newItem";
    }
    return $newItem;
}
		

sub pad_right {
    my ($item, $size, $padding) = @_;
    my $newItem = $item;
    
    $padding = ' ' unless defined $padding;
    
    while( length $newItem < $size ) {
	$newItem .= $padding;
    }
    return $newItem;
}

sub numberFormat{
    my( $number, $whole, $frac ) = @_;
    return pad_left('0',$whole,'0').'.'.pad_right('0',$frac,'0')if $number == 0;
    return pad_left($number,$whole,'0') unless $number =~ /\./ || $frac; 
    my ($left,$right);
    ($left,$right) = split /\./, $number;
    $left = pad_left($left, $whole, '0');
    if(defined $right){
	$right = pad_right( substr($right,0,$frac), $frac, '0' );
	return "$left\.$right";
    }else{
	$right = pad_right( '0', $frac, '0');
	return "$left\.$right";
    }
}
1;
