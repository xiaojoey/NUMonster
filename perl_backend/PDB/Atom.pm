package PDB::Atom;

use strict;
use warnings;


my %metal= ('LI'=>1,'BE'=>1,'NA'=>1,'MG'=>1,'K'=>1,'CA'=>1,
	    'SC'=>1,'TI'=>1,'V'=>1,'CR'=>1,'MN'=>1,'FE'=>1,
	    'CO'=>1,'NI'=>1,'CU'=>1,'ZN'=>1,
	    'AL'=>1,'SI'=>1,'CD'=>1);

##NB: These WOULD have 'N' & 'O' in them 'cept the backbone N/O are uncharged.
##See chargeN() and end of parse()
my %positive=('ARG'=>{'NE'=>1, 'NH1'=>1, 'NH2'=>1},
	      'LYS'=>{'NZ'=>1},
	      'HIS'=>{'ND1'=>1,'ND2'=>1});

my %negative=('ASP'=>{'OD1'=>1,'OD2'=>1},
	      'GLU'=>{'OE1'=>1,'OE2'=>1});

my %hydphb= ('B'=>1,'C'=>1,'S'=>1,
	     'F'=>1,'CL'=>1,'BR'=>1,'I'=>1,
	     'HE'=>1,'NE'=>1,'AR'=>1,'KR'=>1,'XE'=>1,'RN'=>1);

my %polar=  ('O'=>1,'N'=>1,'O\''=>1,'O\'\''=>1);

#
#for identifying hydrogens that need to be renumbered according to IUPAC/PDB format
#
my %formatH=('A'=>{'GLY'=>1},
	     'B'=>{'ASN'=>1,'CYS'=>1,'HIS'=>1,'PHE'=>1,'SER'=>1,'TYR'=>1,'TRP'=>1,'MET'=>1,'LEU'=>1,'GLN'=>1,'GLU'=>1,'PRO'=>1,'ARG'=>1,'LYS'=>1},
	     'G'=>{'MET'=>1,'ILE'=>1,'GLN'=>1,'GLU'=>1,'PRO'=>1,'ARG'=>1,'LYS'=>1},
	     'D'=>{'PRO'=>1,'ARG'=>1,'LYS'=>1},
	     'E'=>{'LYS'=>1});

#
#strictly for identifying residue type
#
my %aas=('GLY'=>1,'ALA'=>1,'VAL'=>1,'CYS'=>1,'SER'=>1,'THR'=>1,'ASN'=>1,
	 'PRO'=>1,'ASP'=>1,'ILE'=>1,'LEU'=>1,'MET'=>1,'GLN'=>1,'GLU'=>1,
	 'HIS'=>1,'LYS'=>1,'PHE'=>1,'TRP'=>1,'TYR'=>1,'ARG'=>1,'ASX'=>1,'GLX'=>1);

my %nas=('A'=>1,'G'=>1,'C'=>1,'T'=>1,'U'=>1,'I'=>1,
	 '+A'=>1,'+C'=>1,'+U'=>1,'+T'=>1,'+G'=>1,'+I'=>1);

#for identifying aromatics
my %aromatics=('TRP'=>{'CB'=>1,'CD1'=>1,'CD2'=>1,'CE2'=>1,'CE3'=>1,'CZ2'=>1,'CZ3'=>1,'CH2'=>1},
	       'TYR'=>{'CG'=>1,'CD1'=>1,'CD2'=>1,'CE1'=>1,'CE2'=>1,'CZ'=>1},
	       'PHE'=>{'CG'=>1,'CD1'=>1,'CD2'=>1,'CE1'=>1,'CE2'=>1,'CZ'=>1},
	       'A'=>{'C8'=>1,'C5'=>1,'C4'=>1,'C6'=>1,'C2'=>1},
	       'G'=>{'C8'=>1,'C5'=>1,'C4'=>1,'C6'=>1,'C2'=>1},
	       'I'=>{'C8'=>1,'C5'=>1,'C4'=>1,'C6'=>1,'C2'=>1},
	       'C'=>{'C2'=>1,'C4'=>1,'C5'=>1,'C6'=>1},
	       'T'=>{'C2'=>1,'C4'=>1,'C5'=>1,'C6'=>1},
	       'U'=>{'C2'=>1,'C4'=>1,'C5'=>1,'C6'=>1},
	       '+A'=>{'C8'=>1,'C5'=>1,'C4'=>1,'C6'=>1,'C2'=>1},
	       '+G'=>{'C8'=>1,'C5'=>1,'C4'=>1,'C6'=>1,'C2'=>1},
	       '+I'=>{'C8'=>1,'C5'=>1,'C4'=>1,'C6'=>1,'C2'=>1},
	       '+C'=>{'C2'=>1,'C4'=>1,'C5'=>1,'C6'=>1},
	       '+T'=>{'C2'=>1,'C4'=>1,'C5'=>1,'C6'=>1},
	       '+U'=>{'C2'=>1,'C4'=>1,'C5'=>1,'C6'=>1},
	       );

my %amines=('LYS'=>{'NZ'=>1},
            'ASN'=>{'ND2'=>1},
	    'GSN'=>{'NE2'=>1},
	    'ARG'=>{'NE'=>1,'CZ'=>1,'NH1'=>1,'NH2'=>1},
	   );

#
#Whatif will change modified residues ('+') into
#4 letter code, using space next to residue name.
#Atom will parse for 3 letters, and here's the translation
#first letter is for Deoxy, or Oxy ribose.
#
my %whatif_nas = ('OCY' => 'C',      'DCY' => 'C',
		  'OAD' => 'A',      'DAD' => 'A',
		  'OGU' => 'G',      'DGU' => 'G',
		  'OTH' => 'T',      'DTH' => 'T',
		  'OUR' => 'U',      'DIN' => 'I',
		  'OIN' => 'I');

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
	$self->{'class'}='';#involvment in a bond
	$self->{'chain'}=''; #Used to store the natural chain
	$self->{'current'}=''; #Used to store the chain being used
	$self->{'role'}='';#donor or acceptor
	$self->{'AN'} = '';
	$self->{'AE'}='';
	$self->{'HN'}='';
	$self->{'AR'}='';
	$self->{'AB'}='';
	$self->{'atom'}='';
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
	$self->{'format'}=''; #either 'IUPAC' or 'PDB'
	
	$self->{'CI'} = ();

	$self->{'area'}=0;
	$self->{'percent'}=0;
	$self->{'Rarea'}=0;
	$self->{'Rpercent'}=0;

	$self->{'heavy'}='';

	bless $self, $class;

	$self->parse;

	#overwrite atom number if given
	$self->{'AN'} = $args{'-number'} if $args{'-number'};

	return $self;
}

sub parse{
    my $self=shift;
    my $junk="";
    ($self->{'type'}, $self->{'AN'}, $self->{'atom'}, $self->{'AL'}, $self->{'R'}, 
     $self->{'CI'}[0], $self->{'RN'}, $self->{'IC'}, $self->{'X'}, 
     $self->{'Y'}, $self->{'Z'}, $self->{'OC'}, $self->{'TE'}, $junk, 
     $self->{'SI'}, $self->{'E'}, $self->{'C'}) = unpack("A6 A5 x A4 A A3 x A A4 A x3 A8 A8 A8 A6 A6 A6 A4 A2 A2", $self->{'string'});
    
    $self->{'R'}=$whatif_nas{$self->{'R'}} if $whatif_nas{$self->{'R'}};

    #clean whitespace
    #NB do NOT clean whitespace for CI, may not exist for water
    #or hetatms
    #
    foreach ($self->{'AN'}, $self->{'atom'},$self->{'R'}, 
	     $self->{'RN'}, $self->{'X'}, $self->{'Y'}, 
	     $self->{'Z'}, $self->{'OC'}, $self->{'TE'}, 
	     $self->{'SI'}, $self->{'E'}, $self->{'C'}){
	$_ =~ s/^\s+|\s+$//g;
    }

    ######################
    #Whatif corrections
    #for D/RNA
    #i) move phosphate numbers
    #ii) translate wi terminal Oxygens from 'T' to '*'
    #iii) change all primes to '*'
    
    if($self->{'atom'} =~ /^OP(\d)$/){
	$self->{'atom'} = "O$1P";
    }elsif($self->{'atom'} =~ /^O([35])T$/){
	$self->{'atom'} = "O$1\*";
    }else{
	$self->{'atom'} =~ s/\'/\*/g;
    }
    #####################
    #The following mess attempts to assign
    #the correct atom element, remoteness, branch
    #and hydrogen number
    #numerous corrections have been made to accomodate for:
    #IUPAC format
    #PDB format
    #NA protons (remoteness can be number)
    #WhatIf mistakes
    ####################
    if($aas{$self->{'R'}}){
	$junk = substr($self->{'atom'}, 0, 1);    
	if($junk =~ /\d/){
	    $self->{'HN'} = $junk;
	}
	else{$self->{'AE'} = $junk;}
	
	$junk = substr($self->{'atom'}, 1, 1);
	if($self->{'AE'}){$self->{'AR'}=$junk;}
	else{$self->{'AE'} = $junk;}

	#terminal protons in IUPAC format
	if($self->{'AR'} =~ /\d/ && $aas{$self->{'R'}}){
	    $self->{'HN'} = $self->{'AR'};
	    $self->{'AR'} = '';
	}
	
	if(length($self->{'atom'})>2){
	    $junk = substr($self->{'atom'}, 2, 1);
	    if($self->{'AR'}){$self->{'AB'}=$junk;}
	    else{$self->{'AR'} = $junk;}
	    
	    if(length($self->{'atom'}) == 4){
		$junk = substr($self->{'atom'}, 3, 1);
		$self->{'AB'} = $junk unless $self->{'AB'};
		$self->{'HN'} = $junk unless $self->{'HN'};
	    }
	}
	
	#Whatif may add protons to the OD2 in ASP and GLU
	if($self->{'R'} =~ /(ASP)|(GLU)/ && $self->{'atom'} =~ /2H([DE])/){
	    $self->{'AE'} = 'H';
	    $self->{'AR'} = $1;
	    $self->{'AB'} = '2';
	    $self->{'HN'} = '';
	}

	if($self->{'atom'} eq "OXT"){
	    $self->{'AR'} = 'X';
	    $self->{'AB'} = 'T';
	}
    }elsif($nas{$self->{'R'}}){
	$junk = substr($self->{'atom'}, 0, 1);   
	if($junk =~ /\d|\*/){
	    $self->{'HN'} = $junk;
	}
	else{$self->{'AE'} = $junk;}
	
	$junk = substr($self->{'atom'}, 1, 1);
	if($self->{'AE'}){$self->{'AR'}=$junk;}
	else{$self->{'AE'} = $junk;}
	
	if(length($self->{'atom'})>2){
	    $junk = substr($self->{'atom'}, 2, 1);
	    if($self->{'AR'}){$self->{'HN'}=$junk;}
	    else{$self->{'AR'} = $junk;}

	    #for C5M
	    if($self->{'HN'} eq 'M'){
		$self->{'AB'} = 'M';
		$self->{'HN'} = '';
	    }
	
	    if(length($self->{'atom'}) == 4){
		$junk = substr($self->{'atom'}, 3, 1);
		$self->{'AB'} = $junk unless $self->{'AB'};
		$self->{'HN'} = $junk unless $self->{'HN'};
	    }
	}
    }

    ###########################
    setClass($self);

    $self->{'chain'}=$self->{'CI'}[0];
    $self->{'current'}=$self->{'CI'}[0];
}

sub isValid{
    my $self=shift;
    my $r=0;
    if($aas{$self->{'R'}}){$r=1;}
    if($nas{$self->{'R'}}){$r=1;}
    return $r;
}

sub setClass{
    my $self=shift;
    #Charge 'O' to negative if attached to NA phosphate...
    if($self->{'atom'} =~ /O[12]P/ || $self->{'atom'} =~ /OP[12]/){
	$self->{'class'}= 'NEG'; 
    }

    if($positive{$self->{'R'}}{$self->{'atom'}} || $metal{$self->{'AE'}}) {
	$self->{'class'}= 'POS';
    }elsif($negative{$self->{'R'}}{$self->{'atom'}}){
	$self->{'class'}= 'NEG';
    }elsif($hydphb{$self->{'AE'}}){
	$self->{'class'}= 'HYDPHB';
    }
}

#NB: multiple chain ids possible, please use correct function
#GETTERS
sub type{my $self=shift; return $self->{'type'};}
sub atomNumber{my $self=shift; return $self->{'AN'};}
sub atomName{
    my $self=shift;
    #
    #exception to changes in H numbers is ILE G2 branch.
    #
    if($_[0]){
	my $hn = $self->{'HN'};
	if($_[0] eq 'IUPAC'){
	    if($self->{'AE'} eq 'H' && $self->{'format'} eq 'PDB' && $formatH{$self->{'AR'}}{$self->{'R'}}){
		$hn++ unless $self->{'R'} eq 'ILE' && $self->{'AB'} == 2;
	    }
	    return $self->{'AE'}.$self->{'AR'}.$self->{'AB'}.$hn;
	}elsif($_[0] eq 'PDB'){
	    if($self->{'AE'} eq 'H' && $self->{'format'} eq 'IUPAC' && $formatH{$self->{'AR'}}{$self->{'R'}}){
		$hn-- unless $self->{'R'} eq 'ILE' && $self->{'AB'} == 2;
	    }
	    return $hn.$self->{'AE'}.$self->{'AR'}.$self->{'AB'};
	}
    }else{
	return $self->{'atom'};
    }
}
sub atomEl{my $self=shift; return $self->{'AE'};}
sub hydNumber{my $self=shift; return $self->{'HN'};}

sub atomRemote{my $self=shift; return $self->{'AR'};}
sub atomBranch{my $self=shift; return $self->{'AB'};}

sub altLoc{my $self=shift; return $self->{'AL'};}
sub resName{my $self=shift; return $self->{'R'};}
sub chainId{my $self=shift; return $self->{'CI'}[0];}
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
sub class{my $self=shift; return $self->{'class'};}
sub area{my $self=shift; return $self->{'area'};}
sub percent{my $self=shift; return $self->{'percent'};}
sub format{my $self=shift; return $self->{'format'};}

sub model{my $self=shift; return $self->{'model'};}
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
sub setFormat{my $self=shift; $self->{'format'}=$_[0];}

sub proton{my $self=shift; return 1 if $self->{'AE'} eq 'H';}
sub NAproton{my $self=shift; return 1 if $self->{'AE'} eq 'H' && $nas{$self->{'R'}};}
sub AAproton{my $self=shift; return 1 if $self->{'AE'} eq 'H' && $aas{$self->{'R'}};}

sub setCurrentChain{my $self=shift; $self->{'current'}=$_[0] if $_[0];$self->{'current'} = $self->{'CI'}[0] unless $_[0];}
sub currentChain{my $self=shift;return $self->{'current'};}

sub mainHeavy{my $self=shift; return 1 if(atomName($self) eq 'N' || atomName($self) eq 'C' || 
					  atomName($self) eq 'O' || atomName($self) eq 'CA' 
					  || atomName($self) =~ /O\'+/);}
sub sideHeavy{my $self=shift; return 1 if(!proton($self) && !mainHeavy($self));}

sub heavy{my $self=shift;return $self->{'heavy'};}
sub setHeavy{
#
#*HO2 in RNA is unique
#HT1/2 also present
#H3/5T also present in NAs
    my ($self,$pdb,$a)=@_;
    my $heavy = $pdb->atom($a);
    if($aas{$self->{'R'}}){
	return if $heavy->atomName eq 'C' || $heavy->atomName eq 'O'; #dont have hydrogens
	if($heavy->atomName eq 'N' && ($self->{'atom'} =~ /^[123]?HT?[123]?$/)){
	    $self->{'heavy'}=$heavy->atomNumber;
	    return;
	}
	if($self->{'AR'} eq $heavy->atomRemote){
	    if($self->{'AB'} eq $heavy->atomBranch){
		$self->{'heavy'}=$heavy->atomNumber;
		setClass($self);
		return;
	    }
	    if(!$heavy->atomBranch){
		$self->{'heavy'}=$heavy->atomNumber;
		$self->{'HN'} = $self->{'AB'};
		$self->{'AB'} = '';
		return;
	    }
	}
    }elsif($nas{$self->{'R'}}){
	if($self->atomName eq "\*HO2" && $heavy->atomName eq "O2\*"){ #Ribose, not DeoxyRibose
	    $self->{'heavy'}=$heavy->atomNumber;
	    return;
	}
	if($self->{'AB'} eq '*' || $self->{'HN'} =~ /T|\*/){
	    if($heavy->hydNumber eq '*'){
		if($self->{'AR'} eq $heavy->atomRemote && $self->{'AB'} eq $heavy->hydNumber && $heavy->atomEl =~ /C|N/){
		    $self->{'heavy'}=$heavy->atomNumber;
		    return;
		}
	    }else{
		return;
	    }
	}
	if($self->{'HN'} =~ /\d/ && $self->{'AR'} eq $heavy->atomRemote){
	    if($heavy->atomBranch eq '*'){
		return;
	    }
	    if($heavy->atomEl =~ /C|N/){
		unless(($self->{'R'} =~ /A/ && $self->{'AR'} == 6 && $heavy->atomEl eq 'C')||
		       ($self->{'R'} =~ /C/ && $self->{'AR'} == 4 && $heavy->atomEl eq 'C')||
		       ($self->{'R'} =~ /G/ && $self->{'AR'} == 2 && $heavy->atomEl eq 'C')||
		       ($self->{'R'} =~ /T/ && $self->{'AR'} == 5 && $heavy->atomEl eq 'C' && $heavy->atomBranch ne 'M')){
		    $self->{'heavy'}=$heavy->atomNumber;
		    return;
		}else{
		    return;
		}
	    }
	}
	if($self->{'AR'} eq $heavy->atomRemote && $self->{'HN'} eq $heavy->hydNumber && $heavy->atomEl =~ /C|N/){
	    $self->{'heavy'}=$heavy->atomNumber;
	    return;
	}
    }
}

sub clearChainIds{my $self=shift; @{$self->{'CI'}}=();}
sub findChainId{
    my ($self,$c)=@_;
    foreach my $ch(@{$self->{'CI'}}){return 1 if $ch eq $c;}
    return undef;
}
sub onlyEq{
    my $self=shift;
    return 0 if scalar($self->{'CI'}) == 1;
    return 1 if $self->{'CI'}[0] eq $_[0];
}

sub chargeN{
    my $self=shift;
    $self->{'class'}='POS';
}

sub naturalChain{ my $self=shift;return $self->{'chain'};}
sub setNaturalChain{ my $self=shift;$self->{'chain'}=shift;}

sub setContact{my $self=shift;($self->{'area'},$self->{'percent'})=@_;}
sub addContact{my $self=shift;
	       $self->{'area'}+=$_[0];
	       $self->{'percent'}+=$_[1];
	   }
sub isContact{my $self=shift;return $self->{'area'};}

sub setRContact{my $self=shift;($self->{'Rarea'},$self->{'Rpercent'})=@_;}
sub Rarea{my $self=shift; return $self->{'Rarea'};}
sub Rpercent{my $self=shift; return $self->{'Rpercent'};}

sub isNA{my $self = shift; return 1 if $nas{$self->{'R'}};return 0;}
sub isAA{my $self = shift; return 1 if $aas{$self->{'R'}};return 0;}
sub resType{
    my $self=shift;
    return 'NA' if $nas{$self->{'R'}};
    return 'AA' if $aas{$self->{'R'}};
    return undef;
}

sub toString{my $self = shift;return $self->{'string'};}

sub toShortstring{
    my $self = shift;
    my $cs;
    foreach(@{$self->{'CI'}}){$cs.=$_;}
    return $self->{'AE'}." ".$self->{'RN'}." ".$cs;
}

sub isAromatic{
    my $self=shift;
    return $aromatics{$self->{'R'}}{$self->{'atom'}};
}

sub isAmine{
	my $self=shift;
	return $amines{$self->{'R'}}{$self->{'atom'}};

}
#
#For comparison to Hetatms
#
sub water{my $self=shift; return 1 if $self->{'R'} eq 'HOH';}
1;
