package PDB::Bonds;

use strict;
use warnings;

use PDB::Utils qw( &dist );
use XML::Out;
use PDB::Writer qw( &pad_left );
use PDB::Bond;

my $HYDPHB = '5';
my $ELCSTA = '7';

my %lengths = ('GLY'=>4,'ALA'=>4,'VAL'=>4,'CYS'=>4,'SER'=>4,'THR'=>4,'ASN'=>6,
	       'PRO'=>6,'ASP'=>6,'ILE'=>6,'LEU'=>6,'MET'=>7,'GLN'=>7,'GLU'=>7,
	       'HIS'=>7,'LYS'=>9,'PHE'=>9,'TRP'=>10,'TYR'=>10,'ARG'=>12,
	       'A'=>18,'G'=>18,'C'=>18,'T'=>18,'U'=>17,'I'=>18,
	       'DA'=>18,'DC'=>18,'DU'=>17,'DT'=>18,'DG'=>18,'DI'=>18,
	       '+A'=>18,'+C'=>18,'+U'=>17,'+T'=>18,'+G'=>18,'+I'=>18,
	       'UNK'=>0); #unknown

sub new{
    my $class = shift;
    my $self={};

    $self->{'bonds'} = {};
    $self->{'models'} = {};
 
    bless $self, $class;
    return $self;
}

sub newBond{
    my $self=shift;
    my ($a1,$a2,$m,$t)=@_;
    
    #if($t && $t eq 'H2OHYD'){
	#print $a1->toString;
	#print $a2->toString;
    #}
    
    my $bond = new PDB::Bond($a1,$a2,$m,$t);
    
    my ($temp, $ta1, $ta2, $tc1, $tc2);
    if($bond){
	if(exists $self->{'bonds'}{$m} && $a1->proton){
	    for(my $i=0;$i < scalar(@{$self->{'bonds'}{$m}}); $i++){
		$temp = ${$self->{'bonds'}{$m}}[$i];
		($ta1, $tc1) = $temp->atom('1');
		($ta2, $tc2) = $temp->atom('2');
		if($a1->heavy == $ta1 || $a1->heavy == $ta2){
		    return '';
		}
	    }
	}
        if(exists $self->{'bonds'}{$m} && $a2->proton){
	   for(my $i=0;$i < scalar(@{$self->{'bonds'}{$m}}); $i++){
	       $temp = ${$self->{'bonds'}{$m}}[$i];
	       ($ta1, $tc1) = $temp->atom('1');
	       ($ta2, $tc2) = $temp->atom('2');
	       if($a2->heavy == $ta1 || $a2->heavy == $ta2){
		   return '';
	       }
	   }
       }
    
        if($bond->type eq "HYBOND" && exists $self->{'bonds'}{$m}){
	    for(my $i=0;$i < scalar(@{$self->{'bonds'}{$m}}); $i++){
		$temp = ${$self->{'bonds'}{$m}}[$i];
		if($temp->type eq "ELCSTA"){
		    ($ta1, $tc1) = $temp->atom('1');
		    ($ta2, $tc2) = $temp->atom('2');
		    if(($a1->atomNumber == $ta1 && $a2->atomNumber == $ta2)||
		       ($a1->atomNumber == $ta2 && $a2->atomNumber == $ta1)){
			${$self->{'bonds'}{$m}}[$i]->setType("SLTBDG");
			$bond->setType("SLTBDG"); 
		    }
		}   
	    }
	}

	push(@{$self->{'bonds'}{$m}}, $bond) unless $bond->type eq "SLTBDG";

	foreach my $model(@{$self->{'models'}{$bond->shortString($a1->resNumber,
								 $a1->resName, 
								 $a1->currentChain,
								 $a2->resNumber,
								 $a2->resName, 
								 $a2->currentChain)}}){
	    ##
	    ##incrementing models means bonds get added repeatedly
	    ##this avoids that problem
	    $m = '0' if $m eq $model;
	}
	push @{$self->{'models'}{$bond->shortString($a1->resNumber,
						    $a1->resName,
						    $a1->currentChain,
						    $a2->resNumber,
						    $a2->resName, 
						    $a2->currentChain)}}, $m if $m;
    }
    return $bond;
}

sub checkBond{
    my $self=shift;
    my ($a1,$a2,$d)=@_;
    my $value = dist($a1->x,$a2->x,$a1->y,$a2->y,$a1->z,$a2->z)<$d ? 1: 0;
    return $value;
}

sub notClose{
    my $self=shift;
    my ($a1,$a2,$r)=@_;

    if(!$lengths{$r}){
	print STDERR "Warning missing radii for ".$r."\n";
	return 1;
    }

    my %hash = %$a2;
    my $cutoff = 7 + $lengths{$r};
    my $dist = dist($a1->x,$hash{'x'},$a1->y,$hash{'y'},$a1->z,$hash{'z'});
    my $value = $dist<$cutoff ? 0 : 1;
    return $value;
}

sub notClose2{
    my $self=shift;
    my ($a1,$a2)=@_;
    if(!$lengths{$$a1{'r'}} || !$lengths{$$a2{'r'}}){	
	print "--".$$a1{'r'}."--\t--".$$a2{'r'}."--\n";
	return 1;
    }

    my $cutoff = $lengths{$$a1{'r'}} + 7 + $lengths{$$a2{'r'}};
    my $dist = dist($$a1{'x'},$$a2{'x'},$$a1{'y'},$$a2{'y'},$$a1{'z'},$$a2{'z'});
    my $value = $dist<$cutoff ? 0 : 1;
    return $value;
}

sub printBonds{
    my $self=shift;
    my $pdb=shift;
    my $file = shift;
    my $m = shift;

    my $bool = 0;
    foreach my $b(@{$self->{'bonds'}{$m}}){
	$bool = 1 if $b->fullString($pdb,@_);
    }

    if($bool){
	open(FH, "> ".$file); 
	
	print FH "ChRes\tAtom\tArea\tPct\t<---Type(Dist)--->\tChRes\tAtom\tArea\tPct\n";
	print FH "|---|\t|--|\t|---|\t|---|\t|----------------|\t|---|\t|--|\t|---|\t|---|\n";
	
	my %Residue_Bonds=();
	foreach my $b(@{$self->{'bonds'}{$m}}){

#	    my $atom1=$pdb->atom($b->{'one'});
#	    my $atom2=$pdb->atom($b->{'two'});

	    print FH $b->fullString($pdb,@_)."\n" if $b->fullString($pdb,@_);
	}
	close(FH);
    }
}

sub printXMLBonds{
    my $self=shift;
    my $pdb=shift;
    my $file=shift;
    my $m = shift;
    
    my $bool = 0;
    foreach my $b(@{$self->{'bonds'}{$m}}){
	$bool = 1 if $b->fullString($pdb,@_);
    }
    if($bool){
	open(FH, "> ".$file); 
	print FH '<?xml version="1.0"?>'."\n";
	print FH '<BONDS>'."\n";
	foreach my $b(@{$self->{'bonds'}{$m}}){
	    print FH XML::Out->write($pdb,$m,$b)."\n" if $b->fullString($pdb,@_);
	}
	print FH '</BONDS>'."\n";
	close(FH);
    }
}

sub printModelCount{
    my $self=shift;
    my $pdb=shift;
    my $file=shift;
    my $cutoff = shift;

    open(FH, "> ".$file); 
    print FH "Ch   Res   <---Type-->Ch   Res  Count The models this bond is found in\n";
    print FH "|-|-------|-----------|-|-------|----|------------------------------>\n";

    my @mods;
    my ($res1, $res2);
    my ($rw1,$rw2);
    foreach my $b( keys %{$self->{'models'}} ){
	$b =~ /(\w{1})(\d+)(\w{1,3})<-(\w{6})->(\w{1})(\d+)(\w{1,3})/;
	$res1 = pad_left($2,3);
	$res2 = pad_left($6,3);
	$rw1 = pad_left($3,3);
	$rw2 = pad_left($7,3);
	@mods=();

	if(scalar(@{$self->{'models'}{$b}}) >= $cutoff){

	    foreach my $m(@{$self->{'models'}{$b}}){push @mods, $m;};
	    print FH " $1 $res1 $rw1   $4    $5 $res2 $rw2  ".scalar(@{$self->{'models'}{$b}})."  ".join(" ", @mods)."\n" if PDB::Bond->checkChains($b,@_); 
	}
    }
    close(FH);
}

sub printXMLModelCount{
    my $self=shift;
    my $pdb=shift;
    my $file=shift;
    my $cutoff = shift;
    
    open(FH, "> ".$file); 
    print FH '<?xml version="1.0"?>'."\n";
    print FH '<BONDS>'."\n";
    my @mods;

    foreach my $b( keys %{$self->{'models'}} ){
	@mods=();
	if(scalar(@{$self->{'models'}{$b}}) >= $cutoff){
	    foreach my $m(@{$self->{'models'}{$b}}){push @mods, $m;};
	    print FH XML::Out->write2($b, @mods)."\n" if PDB::Bond->checkChains($b,@_);
	}
    }
    print FH '</BONDS>'."\n";
    close(FH);
}
1;
