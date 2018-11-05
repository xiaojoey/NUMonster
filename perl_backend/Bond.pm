package Bond;

use strict;
use warnings;

use PDB::Writer qw( &numberFormat );

my $HYDPHB = '5';
my $ELCSTA = '7';

sub new{
    my $class = shift;
    my $self={};
    my $a1 = shift;
    my $a2 = shift;

    #donor is always first, and acceptor is always second as per HBplus output
    #but double check water first
    $self->{'one'}=$a1->atomNumber;
    $self->{'c1'}=$a1->currentChain;
    $self->{'two'}=$a2->atomNumber;
    $self->{'c2'}=$a2->currentChain;

    $self->{'model'}=$_[0];
    $self->{'type'}=$_[1];
    $self->{'dist'}=' ';

    #Changed to heavy BEFORE bond and dist found.(if proton)
    #Ensures 'true' distance btw heavy atoms
    $self->{'one'} = $a1->heavy if $a1->proton;
    $self->{'two'} = $a2->heavy if $a2->proton;

    unless($self->{'type'}){
	return undef unless isHydphb($self,$a1,$a2) || isElcsta($self,$a1,$a2);
    }else{
	$self->{'dist'}=dist($a1->x, $a2->x,$a1->y, $a2->y,$a1->z, $a2->z);
    }

    $self->{'DHA'}=' ';
    $self->{'HA'}=' ';
    $self->{'HAAA'}=' ';
    $self->{'DAAA'}=' ';
        
    bless $self, $class;
    return $self;
}

sub fullString{
    my $self=shift;
    my ($pdb,$c1,$c2)=@_;

    return undef unless $self->{'c1'} =~ /$c1|$c2/ && $self->{'c2'} =~ /$c1|$c2/;
    my $a1 = $pdb->atom($self->{'one'});
    my $a2 = $pdb->atom($self->{'two'});

    my $string = " ".$self->{'c1'}.$a1->resNumber."\t ".$a1->atomName."\t".numberFormat($a1->area,2,2)."\t".numberFormat($a1->percent,2,2)."\t";
    $string .= "<--".$self->{'type'}."(".$self->{'dist'}.")-->\t";
    $string .= " ".$self->{'c2'}.$a2->resNumber."\t ".$a2->atomName."\t".numberFormat($a2->area,2,2)."\t".numberFormat($a2->percent,2,2);
    return $string;
}

sub shortString{
    my $self = shift;
    my ($r1,$n1,$c1,$r2,$n2,$c2)=@_;
    return undef unless $self->{'c1'} =~ /$c1|$c2/ && $self->{'c2'} =~ /$c1|$c2/;
    my $string = $self->{'c1'}.$r1.$n1;
    $string .= "<-".$self->{'type'}."->";
    $string .= $self->{'c2'}.$r2.$n2;
    return $string;
}

sub checkChains{
    my $self= shift;
    my $string = shift;
    my ($c1, $c2) = @_;

    $string =~ /([A-Z])\d{1,4}[A-Z]{1,3}<-[A-Z]{6}->([A-Z])\d{1,4}[A-Z]{1,3}/;


    if(($c1 eq $1 && $c2 eq $2) ||
       ($c2 eq $1 && $c1 eq $2)){
	#print $c1."\t".$c2."\t".$1."\t".$2."\n";
	return 1;
    }else{
	return 0;
    }
}

sub isHydphb{
    my ($self,$a1,$a2)=@_;
    
    $self->{'dist'} = dist($a1->x, $a2->x,$a1->y, $a2->y,$a1->z, $a2->z);
    #print "HYD: ".$self->{'dist'}."\n";
    $self->{'type'}='HYDPHB', return 1 if $self->{'dist'} < $HYDPHB && $a1->class eq 'HYDPHB' && $a2->class eq 'HYDPHB';
    return undef;
}

sub isElcsta{
    my ($self,$a1,$a2)=@_;

    $self->{'dist'} = dist($a1->x, $a2->x,$a1->y, $a2->y,$a1->z, $a2->z);
    $self->{'type'}='ELCSTA', print "FOUND\n", return 1 if $self->{'dist'} < $ELCSTA && 
	(($a1->class eq 'POS' && $a2->class eq 'NEG') ||
	 ($a1->class eq 'NEG' && $a2->class eq 'POS'));
    return undef;
}

sub dist{my $self=shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my ($x1, $x2, $y1, $y2, $z1, $z2)=@_;

    return numberFormat(sqrt ( ($x1 - $x2)**2 +
			       ($y1 - $y2)**2 +
			       ($z1 - $z2)**2 ),
			1,2);
}

sub type{my $self=shift;return $self->{'type'};}
sub setType{my $self=shift;$self->{'type'}=shift;}
sub getDist{my $self=shift;return $self->{'dist'};}
sub atom{my ($self,$n)=@_; 
	 return ($self->{'one'},$self->{'c1'}) if $n eq '1';
	 return ($self->{'two'},$self->{'c2'}) if $n eq '2';
	 return undef;
}

sub addHbond{
    my $self= shift;
    $self->{'dist'}=shift;
    $self->{'DHA'}=shift unless $_[0] =~ /^-/;
    $self->{'HA'}=shift unless $_[0] =~ /^-/;
    $self->{'HAAA'}=shift unless $_[0] =~ /^-/;
    $self->{'DAAA'}=shift unless $_[0] =~ /^-/;
}
1;
