package PDB::Hetatm;

use strict;
use warnings;

#atom number(7-11), atom name(13-16) & alternate location(17)
#residue name(18-20), chain ID(22), residue number(23-26) & insertion code(27)
#x coords(31-38), y coords(39-46) & z coords(47-54) & occupancy(55-60)
#temperature(61-66), segment ID(73-76), element(77-78) & charge(79-80)

#atom element(13-14), atom remoteness(15) & atom branch(16)

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};
	
	$self->{'string'}=$args{'-line'};
	$self->{'model'}='';
	$self->{'type'} = '';
	$self->{'chain'}=''; #Used to store the natural chain
	$self->{'current'}=''; #Used to store the chain being used
	$self->{'atom'} = ''; #full atom name
	$self->{'AN'} = '';
	$self->{'A'} = '';
	$self->{'AE'}='';
	$self->{'AR'}='';
	$self->{'AB'}='';
	$self->{'AL'} = '';
	$self->{'R'} = '';
	$self->{'RN'} = '';
	$self->{'IC'} = '';
	$self->{'X'} = '';
	$self->{'Y'} = '';
	$self->{'Z'} = '';
	$self->{'OC'} = '';
	$self->{'TE'} = '';
	$self->{'SI'} = '';
	$self->{'E'} = '';
	$self->{'C'} = '';
	$self->{'HN'}='';
	$self->{'CI'} = ();

	$self->{'area'}=0;
	$self->{'percent'}=0;
	$self->{'Rarea'}=0;
	$self->{'Rpercent'}=0;
	
	$self->{'heavy'}='';

	bless $self, $class;

	$self->parse;

	return $self;
}
sub parse{
    my $self=shift;
    my $junk="";
    if($self->{'string'} =~ /^HETATM/){
	($self->{'type'}, $self->{'AN'}, $self->{'AE'},$self->{'AR'},$self->{'AB'}, $self->{'AL'}, $self->{'R'}, 
	 $self->{'CI'}[0], $self->{'RN'}, $self->{'IC'}, $self->{'X'}, 
	 $self->{'Y'}, $self->{'Z'}, $self->{'OC'}, $self->{'TE'}, $junk,
	 $self->{'SI'}, $self->{'E'}, $self->{'C'}) = unpack("A6 A5 x A2 A A A A3 x A A4 A x3 A8 A8 A8 A6 A6 A6 A4 A2 A2", $self->{'string'});
	
	#clean whitespace
	foreach ($self->{'AN'}, $self->{'AE'}, $self->{'R'}, 
		 $self->{'RN'}, $self->{'X'}, $self->{'Y'}, 
		 $self->{'Z'}, $self->{'OC'}, $self->{'TE'}, 
		 $self->{'SI'}, $self->{'E'}, $self->{'C'}){
	    $_ =~ s/^\s+|\s+$//g;
	}
	
	if($self->{'AE'} =~ /(\d?)H(\d?)/){
	    $self->{'AE'} = 'H';
	    $self->{'HN'} = $1;
	}
    }
}

sub type{my $self=shift; return $self->{'type'};}
sub atomNumber{my $self=shift; return $self->{'AN'};}
sub atom{my $self=shift; return $self->{'atom'};}
sub atomName{my $self=shift; return $self->{'AE'}.$self->{'AR'}.$self->{'AB'};}
sub atomEl{my $self=shift; return $self->{'AE'};}
sub hydNumber{my $self=shift; return $self->{'HN'};}
sub atomRemote{my $self=shift; return $self->{'AR'};}
sub atomBranch{my $self=shift; return $self->{'AB'};}
sub altLoc{my $self=shift; return $self->{'AL'};}
sub resName{my $self=shift; return $self->{'R'};}

#
#Hetatms, other than water, are irregular in chain ids
#so chain ids becomes current chainid ('_' if none) plus
#residue name
#
sub chainId{
    my $self=shift;
    if(!$self->water){
	if(!$self->{'CI'}[0]){
	    return '_'.$self->{'R'};
	}else{
	    return $self->{'CI'}[0].$self->{'R'};
	}
    }
    return $self->{'CI'}[0];
}
sub chainIds{my $self=shift; return $self->{'CI'};}
sub resNumber{my $self=shift; return $self->{'RN'};}
sub insCode{my $self=shift; return $self->{'IC'};}
sub x{my $self=shift; return $self->{'X'};}
sub y{my $self=shift; return $self->{'Y'};}
sub z{my $self=shift; return $self->{'Z'};}
sub occ{my $self=shift; return $self->{'OC'};}
sub temp{my $self=shift; return $self->{'TE'};}
sub segId{my $self=shift; return $self->{'SI'};}
sub el{my $self=shift; return $self->{'E'};}
sub charge{my $self=shift; return $self->{'C'};}
sub water{my $self=shift; return 1 if $self->{'R'} eq 'HOH';}
sub model{my $self=shift; return $self->{'model'};}
sub area{my $self=shift; return $self->{'area'};}
sub percent{my $self=shift; return $self->{'percent'};}

sub setModel{my $self=shift; $self->{'model'}=$_[0];}


#SETTERS
sub setType{my $self=shift; $self->{'type'}=$_[0];}
sub setAtomNumber{my $self=shift; $self->{'AN'}=$_[0];}
sub setAtomEl{my $self=shift; $self->{'AE'}=$_[0];}
sub setAtomRemote{my $self=shift; $self->{'AR'}=$_[0];}
sub setAtomBranch{my $self=shift; $self->{'AB'}=$_[0];}
sub setAltLoc{my $self=shift; $self->{'AL'}=$_[0];}
sub setResName{my $self=shift; $self->{'R'}=$_[0];}
sub setChainId{my $self=shift; $self->{'CI'}[0]=$_[0];}
sub addChainIds{my $self=shift; push @{$self->{'CI'}}, @_;}
sub setResNumber{my $self=shift; $self->{'RN'}=$_[0];}
sub setInsCode{my $self=shift; $self->{'IC'}=$_[0];}
sub setX{my $self=shift; $self->{'X'}=$_[0];}
sub setY{my $self=shift; $self->{'Y'}=$_[0];}
sub setZ{my $self=shift; $self->{'Z'}=$_[0];}
sub setOcc{my $self=shift; $self->{'OC'}=$_[0];}
sub setTemp{my $self=shift; $self->{'TE'}=$_[0];}
sub setSegId{my $self=shift; $self->{'SI'}=$_[0];}
sub setEl{my $self=shift; $self->{'E'}=$_[0];}
sub setCharge{my $self=shift; $self->{'C'}=$_[0];}

sub clearChainIds{my $self=shift; @{$self->{'CI'}}=();}

sub toString{
    my $self = shift;
    my %args=@_;
    my @keys = keys %args;
    my $boolean=1;

    for(my $i=0;$i<scalar(@keys);$i++){
	if($self->{$keys[$i]} eq $args{$keys[$i]}){
	    $boolean=1;
	}else{$boolean=0;}
    }
    print $self->{'string'} if $boolean;
}

sub proton{my $self=shift; return 1 if $self->{'AE'} eq 'H';}
sub isNA{my $self=shift; return 0;}
sub isAA{my $self=shift; return 0;}
sub isHOH{my $self=shift; return 1 if $self->{'R'} eq 'HOH'; return 0;}

sub setCurrentChain{my $self=shift; $self->{'current'}=$_[0] if $_[0];$self->{'current'} = $self->{'CI'}[0] unless $_[0];}
sub currentChain{my $self=shift;return $self->{'current'};}


sub setContact{my $self=shift;($self->{'area'},$self->{'percent'})=@_;}
sub addContact{my $self=shift;
	       $self->{'area'}+=$_[0];
	       $self->{'percent'}+=$_[1];
	   }
sub isContact{my $self=shift;return $self->{'area'};}

sub setRContact{my $self=shift;($self->{'Rarea'},$self->{'Rpercent'})=@_;}
sub Rarea{my $self=shift; return $self->{'Rarea'};}
sub Rpercent{my $self=shift; return $self->{'Rpercent'};}
sub heavy{my $self=shift;return $self->{'heavy'};}

sub setHeavy{
    my ($self,$heavy)=@_;
    $self->{'heavy'}=$heavy->atomNumber if $heavy->resNumber == $self->{'RN'};
    return;
}

sub isCarbonyl{return 0;}
1;
