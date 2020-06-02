package PDB;

use strict;
use warnings;

use PDB::Line;
use PDB::Atom;
use PDB::Hetatm;
use PDB::Utils qw( &dist );

#in use in wiWrite()
use IO::File;

#use in reading in linebreaks '\r' & '\n'
use File::Stream;

#use in reading gzipped files
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

sub new {
	my $class = shift;
	my $self = {};

	$self->{'other'} = {};
	$self->{'atoms'} = {};
	$self->{'hetatms'} = {};
	$self->{'water'} = {};
	$self->{'protons'} = {};
	$self->{'residues'} = {};
	$self->{'models'} = {};
	$self->{'currentModel'} = '';
	$self->{'all'} = {};
	$self->{'contacts'} = {};
	$self->{'chainPairs'}=();
	$self->{'locs'}=();
	$self->{'trueTerminals'}={};

	bless $self, $class;

	return $self;
}

sub setModel{my $self=shift;$self->{'currentModel'}=shift;}
sub getModel{my $self=shift;return $self->{'currentModel'};}
sub getModels{my $self=shift;return keys %{$self->{'models'}};}

sub chainPairs{my $self=shift;return keys %{$self->{'chainPairs'}};}
sub residues{my($self)=@_;return keys %{$self->{'residues'}{$self->{'currentModel'}}};}
sub chainResidues{my $self=shift;
		  return sort {substr($a,1) <=> substr($b,1)} grep {substr($_,0,1) eq $_[0]} $self->residues;
	      }
sub atomsR{my($self,$r)=@_;return sort {$a<=>$b} keys %{$self->{'residues'}{$self->{'currentModel'}}{$r}};}
sub atomsM{my($self,$c)=@_;return sort {$a<=>$b} keys %{$self->{'models'}{$self->{'currentModel'}}{$c}};}

sub atomNumber{my($self,$a)=@_;return $self->{'all'}{$a}->atomNumber;}
sub atom{my($self,$a)=@_;return $self->{'all'}{$a} if $self->{'atoms'}{$a};return undef;}
sub proton{my($self,$p)=@_;return $self->{'all'}{$p} if $self->{'protons'}{$p};return undef;}
sub hetatm{my($self,$h)=@_;return $self->{'all'}{$h} if $self->{'hetatms'}{$h};return undef;}
sub any{my($self,$a)=@_;return $self->{'all'}{$a} if $self->{'all'}{$a};return undef;}
sub water{my($self,$w)=@_;
	  return $self->{'all'}{$w} if $w;
	  return sort {$a <=>$b} keys %{$self->{'water'}{$self->{'currentModel'}}};
      }

sub getAtom{
    my ($self,$c,$r,$name) = @_;
    my $temp;

    if(exists $self->{'residues'}{$self->{'currentModel'}}{$c.$r}){
	foreach my $a (sort {$a<=>$b} keys %{$self->{'residues'}{$self->{'currentModel'}}{$c.$r}}){
	    #print $name."\t".$self->{'all'}{$a}->atomName."\n";
	    $temp = $self->{'all'}{$a},$temp->setCurrentChain($c) if $self->{'all'}{$a}->atomName eq $name;
	    return $temp if $temp;
	}
    }else{
	foreach my $a (sort {$a<=>$b} keys %{$self->{'water'}{$self->{'currentModel'}}}){
	    $temp = $self->{'all'}{$a},$temp->setCurrentChain($c) if $self->{'all'}{$a}->atomName eq $name && $self->{'all'}{$a}->resNumber eq $r;
	    return $temp if $temp;
	}
    }
    return undef;
}

sub getFileHandle{
    my $file=shift;
    my $stream;

    my $fh = new IO::Uncompress::Gunzip($file,Transparent=>1) or die "IO::Uncompress::Gunzip failed on $file: $GunzipError\n";;
    $stream = (File::Stream->new($fh, separator => qr{[\cM\r\n]}))[1];
    return $stream;
}

sub findConformations{
    my $self = shift;
    my $file = shift;

    my $stream = getFileHandle($file);

    my $temp;
    while(<$stream>){
	if($_ =~ /^ATOM/){
	    $temp=new PDB::Atom('-line' => $_);
	    $self->{'locs'}{$temp->altLoc}=1;
	}elsif($_ =~ /^HETATM/){
	    $temp = new PDB::Hetatm('-line' => $_);
	    $self->{'locs'}{$temp->altLoc}=1;
	}
    }
    return sort keys %{$self->{'locs'}};
}

sub wiWrite{
    my $self = shift;
    my $file = shift;
    my $wiResult = shift;
    my $xml=shift;
    my $modelCount=0;

    my @confs = findConformations($self, $file);
    shift @confs if $#confs; #removes empty atlloc if altlocs present

    #for now, only want one conformation
    #subsets may be dealt with later
    #11/4/03 9:45am
    if($#confs){
	for(my $i=0;$i<$#confs;$i++){
	    pop @confs;
	}
    }

    my %fhs = map {
	my $fh = IO::File->new(">> wi$_.pdb") or die "ack [$_]: $!";
	$_ => $fh;
    } @confs;

    my ($temp,$first,$altloc,$chain,$prev);
    $chain=0;

    #NB Whatif NEEDS 'MODEL', but can work without ENDMDL
    my $stream=getFileHandle($file);

    my $print = 1;
    while(<$stream>){
	if($_ =~ /^TER/){
	    foreach my $loc (@confs){
		print {$fhs{$loc}} $_;
	    }
	}elsif($_ =~ /^ATOM/){
	    $temp = new PDB::Atom('-line' => $_);
	    $first = $temp unless $first;
	    if($first){
		if($temp->resNumber eq $first->resNumber && 
		   $temp->chainId eq $first->chainId &&
		   $temp->atomName eq $first->atomName){
		    ##start of first chain in every model
		    $chain="A";
		    $modelCount++;
		    #last if $modelCount==3;
		    foreach my $loc (@confs){
			print {$fhs{$loc}} PDB::Writer->model($modelCount);
		    }
		}
		## in hope that chain ids change.
		if($temp->chainId ne $first->chainId){
		    $chain=0;
		}
	    }

	    $print = 0 if $xml->getProtons && $temp->proton; ##strip protons

	    if($temp->altLoc){
		print {$fhs{$temp->altLoc}} $_ if $print && $fhs{$temp->altLoc};
	    }else{
		foreach my $loc (@confs){
		    ##In anticiption of single chain PDBs with no chain ID.
		    if($chain eq "A" && $temp->chainId eq ""){
			substr($_,21,1)='A';
			print {$fhs{$loc}} $_ if $print;
		    }else{
			print {$fhs{$loc}} $_ if $print;
		    }
		}
	    }
	       
	}elsif($_ =~ /^HETATM/){
	    $temp = new PDB::Hetatm('-line' => $_);
	    $print = 0 if $xml->getProtons && $temp->proton; ##strip protons
	    if($temp->altLoc){
		print {$fhs{$temp->altLoc}} $_  if $print && $fhs{$temp->altLoc};
	    }else{
		foreach my $loc (@confs){
		    print {$fhs{$loc}} $_ if $print;
		}
	    }
	}
	$print=1;
    }
}

sub haadWrite{
    my $self = shift;
    my $file = shift;
}

sub parse{
    my $self=shift;
    my $file=shift;
    my $xml=shift;
    my $bonds = shift;

    my %tChs;
    my $modelCount=0;

    if($xml){
	foreach my $cp($xml->chainpairs){
	    $self->{'chainPairs'}{$cp}=1;
	}
    }

    my $stream=getFileHandle($file);

    my $i=0;
    my ($temp,$first,$chain);
    my($firstH,$secondH,$thirdH,$oxt);

    # I'm adding this code to remember and insert the current chain if it goes missing for some atoms (as in HAAD's new protons)
    my $current_chain="";

    while(<$stream>){
	%tChs=();
	if($_ =~ /^ATOM/){

	    ###################### init & set-up #####################################
	    ########################################################################
	    $i++;
	    #
	    #NB: $temp, $first and $chain are all new copies, to prevent confusion 
	    #when shallow copying referents.
	    #
	    $temp = new PDB::Atom('-line' => $_, '-number'=>$i);

	    if( $temp->chainId ne "" && ( $current_chain eq "" || 
					  ( $current_chain ne $temp->chainId ) ) ){
		$current_chain=$temp->chainId;
	    }

	    if($current_chain ne "" && $temp->chainId eq ""){
#		$temp->setChainId($current_chain);
	    }

	    $first = new PDB::Atom('-line' => $_) unless $first;

	    if($current_chain ne "" && $first->chainId eq ""){
		$first->setChainId($current_chain);
	    }

	    if($first){
		if($temp->resNumber eq $first->resNumber && 
		   $temp->chainId eq $first->chainId &&
		   $temp->atomName eq $first->atomName){
		    
		    $firstH='';
		    $secondH='';
		    $thirdH='';
		    
		    $oxt='';

		    $modelCount++;
		    #print "Model: $modelCount\n";
		}
	    }
	    if($temp->atomName eq 'N' && !$xml){
		if($chain){
		    if($chain->chainId ne $temp->chainId){
			$chain = new PDB::Atom('-line' => $_);

			if($current_chain ne "" && $chain->chainId eq ""){
			    $chain->setChainId($current_chain);
			}

			$temp->chargeN;
		    }
		}else{
		    $chain = new PDB::Atom('-line' => $_);

		    if($current_chain ne "" && $chain->chainId eq ""){
			$chain->setChainId($current_chain);
		    }

		    $temp->chargeN;
		}
	    }

	    ##
	    ##All this is to do with countering whatif's inability to renumber the new terminal protons
	    ##on the second chain, and also the OXT residue.
	    ##They are found on the end of the first chain.
	    ##
	    if($xml && $xml->getProtons && $temp->AAproton){
                if($chain){
		    if($secondH && !$thirdH && $firstH->hydNumber eq '1'){
			$thirdH = new PDB::Atom('-line' =>$_);

			if($current_chain ne "" && $thirdH->chainId eq ""){
			    $thirdH->setChainId($current_chain);
			}

			$thirdH->setModel($modelCount);
			$i--;
			next;
		    }elsif($firstH && !$secondH){
			$secondH  = new PDB::Atom('-line' => $_);

			if($current_chain ne "" && $secondH->chainId eq ""){
			    $secondH->setChainId($current_chain);
			}

			$secondH->setModel($modelCount);
			$i--;
			next;
		    }elsif($oxt && !$firstH){
                        $firstH  = new PDB::Atom('-line' => $_);

			if($current_chain ne "" && $firstH->chainId eq ""){
			    $firstH->setChainId($current_chain);
			}

			$firstH->setModel($modelCount);
                        $i--;
			next;
                    }elsif($chain->chainId ne $temp->chainId && !$oxt && $temp->atomName eq 'OXT'){
                        $oxt = new PDB::Atom('-line' => $_);

			if($current_chain ne "" && $oxt->chainId eq ""){
			    $oxt->setChainId($current_chain);
			}

			$oxt->setModel($modelCount);
			$i--;
			next;
                    }else{
			$chain = new PDB::Atom('-line' => $_);

			if($current_chain ne "" && $chain->chainId eq ""){
			    $chain->setChainId($current_chain);
			}

		    }
                }else{
                    $chain = new PDB::Atom('-line' => $_);

		    if($current_chain ne "" && $chain->chainId eq ""){
			$chain->setChainId($current_chain);
		    }
		}
	    }

	    $temp->setModel($modelCount);
	    $self->{'trueTerminals'}{$temp->naturalChain()}{$temp->resNumber()}=1 unless $modelCount >1;
	    ###################### restrict and clear-up #############################
	    ########################################################################
	    #
            #NB: Whatif handles new terminal protons incorrectly for nucleic residues 
            # 
	    next if $temp->proton && $temp->atomName =~ /^H[123]$/ && $temp->isNA && notTerminalProtons($self,$temp,$bonds);

	    if($xml){
		$temp->clearChainIds;
		foreach my $ch ($xml->chains){
		    #
		    #NB: SHOULD work with multiple models, regardless of atom number
		    #
		    if($temp->resNumber >= $xml->start($ch) && $temp->resNumber <= $xml->end($ch) && $temp->naturalChain eq $xml->naturalChainE($ch)){
			$tChs{$ch}=1;
			$temp->setNaturalChain($xml->naturalChain($ch));
		    }
		}
		if(keys %tChs){
		    $temp->addChainIds(keys %tChs);
		}else{
		    next;
		}
	    }else{		
		#
		#Reserved for possible future use, please do NOT use to pick nose.
		#or floss teeth for that matter either.
		#
	    }

            ##################################### add ####################################################
            #############################################################################################
	    addToMemory($self, $temp, $i);

	    ##
	    ##Following on from Correcting WhatIf misplaced terminal hydrogens
	    ##These Hydrogens are added AFTER 'HA'
	    ##But this happens here, because 'HA' is $temp, and needed to be added first
	    ##Also need to make sure heavy atom is designated
	    if($firstH && $temp->resNumber eq $firstH->resNumber &&
	       $temp->chainId eq $firstH->chainId &&
	       $temp->atomName eq 'HA'){
		$i++;
		$firstH->setAtomNumber($i);
		addToMemory($self, $firstH, $i);

		foreach my $ch(@{$firstH->chainIds}){
                    foreach my $a (sort {$a<=>$b} keys %{$self->{'residues'}{$modelCount}{$ch.$firstH->resNumber}}){
			if($self->{'all'}{$a}->atomName eq 'N'){
			    $firstH->setHeavy($self, $self->{'all'}{$a}->atomNumber);
			    last;
			}
		    }
		}
                $i++;
                $secondH->setAtomNumber($i);
		addToMemory($self, $secondH, $i);
                foreach my $ch(@{$secondH->chainIds}){
		    foreach my $a (sort {$a<=>$b} keys %{$self->{'residues'}{$modelCount}{$ch.$secondH->resNumber}}){
                        if($self->{'all'}{$a}->atomName eq 'N'){
                            $secondH->setHeavy($self, $self->{'all'}{$a}->atomNumber);
                            last;
                        }
                    }
                }
		if($thirdH){
		    $i++;
		    $thirdH->setAtomNumber($i);
		    addToMemory($self, $thirdH, $i);
		    foreach my $ch(@{$thirdH->chainIds}){
			foreach my $a (sort {$a<=>$b} keys %{$self->{'residues'}{$modelCount}{$ch.$thirdH->resNumber}}){
			    if($self->{'all'}{$a}->atomName eq 'N'){
				$thirdH->setHeavy($self, $self->{'all'}{$a}->atomNumber);
				last;
			    }
			}
		    }
		}
	    }

	    if($oxt && $temp->resNumber eq $oxt->resNumber &&
	       $temp->chainId eq $oxt->chainId &&
	       $temp->atomName eq 'O'){
		$i++;
		$oxt->setAtomNumber($i);
		addToMemory($self, $oxt, $i);
	    }
	    
	    if($temp->proton){
		#print $temp->atomName."\n" if $temp->NAproton;
		foreach my $ch(@{$temp->chainIds}){
		    foreach my $a (sort {$a<=>$b} keys %{$self->{'residues'}{$modelCount}{$ch.$temp->resNumber}}){
			last if $temp->heavy;
			$temp->setHeavy($self, $a) if !$self->{'all'}{$a}->proton;
		    }
		}
		unless($temp->{'heavy'}){
		    WebDBI->naming_error($xml,$temp,'heavy');
		}else{
		    #print "PASSED: ".$self->{'all'}{$temp->heavy}->atomName."\n" if $temp->NAproton;
		}
	    }


	    ################# HYDPHB and ELCSTA bond detection #############################
	    ################################################################################
	    foreach my $ch(sort keys %{$self->{'contacts'}{$modelCount}}){
		next if !$xml && $temp->naturalChain eq $ch; #contacts contain natural chains if not xml
		#if $temp has 1 chain and thats the same as $ch, then next.
		next if $xml && $temp->onlyEq($ch);
		#print $temp->chainId.$ch."\n";
		
		foreach my $r (sort {$a <=> $b} keys %{$self->{'contacts'}{$modelCount}{$ch}}){
		    next if $temp->resNumber eq $r && 
			$temp->naturalChain eq $self->{'contacts'}{$modelCount}{$ch}{$r}{'nc'};
		    my $residueAtom = (keys %{$self->{'residues'}{$modelCount}{$ch.$r}})[0];
		    my $residueName = $self->{'residues'}{$modelCount}{$ch.$r}{$residueAtom};
		    next if $bonds->notClose($temp, 
					    $self->{'contacts'}{$modelCount}{$ch}{$r},
					    $residueName);
		    unless($xml){
			$temp->setCurrentChain;
			foreach my $a (sort {$a <=> $b} keys %{$self->{'residues'}{$modelCount}{$ch.$r}}){
			    $self->{'all'}{$a}->setCurrentChain($ch);
			    $self->{'chainPairs'}{$ch.$temp->chainId}=1 if $bonds->newBond($temp,$self->{'all'}{$a},
											  $modelCount);
			}
		    }else{
			#again, contacts contain 'un'natural chains already if xml
			foreach my $ch2 ($xml->getChains($temp->naturalChain)){
			    next if $ch2 eq $ch;
			    $temp->setCurrentChain($ch2);
			    foreach my $a (sort {$a <=> $b} keys %{$self->{'residues'}{$modelCount}{$ch.$r}}){
				$self->{'all'}{$a}->setCurrentChain($ch);
				$bonds->newBond($temp,$self->{'all'}{$a},
					       $modelCount);
			    }
			}
		    }
		}
	    }
	}elsif($_ =~ /^HETATM/){
	    $i++;
	    $temp = new PDB::Hetatm('-line' => $_);
	    $temp->setModel($modelCount);

	    $self->{'all'}{$i}=$temp;

	    if($temp->water){
		$self->{'water'}{$modelCount}{$i} = 1;
	    }else{
		$self->{'hetatms'}{$i} = 1;
	    }
	}else{
	    $temp = new PDB::Line('-line' => $_, 
				  '-model' => $modelCount);
	    $self->{'other'}{$i}=$temp;
	}
    }
}

sub addToMemory{
    my ($self, $atom, $numb) = @_;

    $self->{'all'}{$numb}=$atom;
    unless($atom->proton){
	$self->{'atoms'}{$numb} = 1;
    }else{
	$self->{'protons'}{$numb} = 1;
    }
    
    foreach my $ch(@{$atom->chainIds}){
	$self->{'contacts'}{$atom->model}{$ch}{$atom->resNumber}=residualAverage($atom, $self->{'contacts'}{$atom->model}{$ch}{$atom->resNumber});
	$self->{'residues'}{$atom->model}{$ch.$atom->resNumber}{$numb}=$atom->resName;
	$self->{'models'}{$atom->model}{$ch}{$numb}=1;
    }
}

sub renumber{
    my $self=shift;
    my %temps = ();

    my @temp;
    my $r;
    foreach my $ch ( sort keys %{$self->{'trueTerminals'}}){
	@temp = sort{$a <=> $b} keys %{$self->{'trueTerminals'}{$ch}};
	$r = shift @temp;
	print "$ch$r\n";
	print sort {$a<=>$b} $self->atomsR($self,$ch.$r);
	foreach my $ref (sort {$a<=>$b} $self->atomsR($self,$ch.$r)){
	    #print $self->{'all'}{$ref}->atomName." ".$self->{'all'}{$ref}->atomNumber."\n";
	}
	$r = pop @temp;
        print "$ch$r\n";
	print sort {$a<=>$b} $self->atomsR($self,$ch.$r);
	foreach my $ref (sort {$a <=>$b} $self->atomsR($self,$ch.$r)){
            #print $self->{'all'}{$ref}->atomName." ".$self->{'all'}{$ref}->atomNumber."\n";
        }
    }

    foreach my $a ( sort {$a <=> $b} keys %temps){
	#$self->{'all'}{$a} = $temps{$a};
	foreach my $ch(@{$temps{$a}->chainIds}){
	    #$self->{'residues'}{$temps{$a}->model}{$ch.$temps{$a}->resNumber}{$a}=1;
	    #$self->{'models'}{$temps{$a}->model}{$ch}{$a}=1;
	}
	if($temps{$a} =~ /^PDB::Atom/){
	    unless($temps{$a}->proton){
		#$self->{'atoms'}{$a} = 1;
	    }else{
		#$self->{'protons'}{$a} = 1;
	    }
	}elsif($temps{$a} =~ /^PDB::Hetatm/){
	    if($temps{$a}->water){
		#$self->{'water'}{$a} = 1;
	    }else{
		#$self->{'hetatms'}{$a} = 1;
	    }
	}
    }
    %temps=();
}

sub contact{
    my $self=shift;
    my ($resID,$resname,$atomname,$junk,$area,$pct) = split /\s+/,$_[0];
    my $chain = $_[1];

    foreach my $ref (sort { $a <=> $b } keys %{$self->{'residues'}{$self->{'currentModel'}}{$chain.$resID}}){
	if($self->{'all'}{$ref}->atomName eq $atomname){
	    eval {
		$self->{'all'}{$ref}->addContact($area,$pct);
		$self->{'all'}{$self->{'all'}{$ref}->heavy}->addContact($area,$pct) if $self->{'all'}{$ref}->proton;
	    };
	    if($@){
		print $@;
		print $self->{'all'}{$ref}->atomName."\n";
	    }
	    return $ref;
	}
    }
    return undef;
}

sub residueAP{
    my $self=shift;
    my($resID,$resname,$junk,$area,$pct) = split /\s+/, $_[0];
    my $chain = $_[1];

    foreach my $ref (sort { $a <=> $b } keys %{$self->{'residues'}{$self->{'currentModel'}}{$chain.$resID}}){
	$self->{'all'}{$ref}->setRContact($area,$pct);
	#
	#Commented out because protons point back to heavy atoms anyway
	#$self->{'all'}{$self->{'all'}{$ref}->heavy}->setRContact($area,$pct) if $self->{'all'}{$ref}->proton;
    }
}

sub sortAtoms{
    my $self=shift;
    my @numbers = @_;
    my (%main,@main,@heavy,@proton,%names,@names);
    
    foreach my $a (@numbers){
	$main{$self->{'all'}{$a}->atomName}=$a;
	push @main, $self->{'all'}{$a}->atomName;
    }
    
    #CA is listed specifically for main chain
    
    my %elements = (''  => 0, N  => 1, CA  => 2,   
		    C  => 3, O  => 4, 'O\'' => 5, S => 6, P => 7, H  => 8, 'O\'\'' => 20000);
    
# Using '' => 1 ensures that unadorned main atom weights
# remain in the range 1 to 9.
# Using 10.n  for the distance weights
    my %distances = ('' => 1, B => 10.0, G => 10.1, D => 10.2,
		     E => 10.3,  Z => 10.4, H => 10.5);
    
    my @sorted = map{$main{$_->[1]}}sort {$a->[0]<=>$b->[0]}
    map{m/(\d)?(N|CA|O\'\'|O'|O|C|H|S|P)([BGDEZH])?(\d)?/x or die "Failed to separate '$_'";
	[$elements{$2}             ## 1 .. 9
	 * $distances{$3 || ''}      ## 1 or 10.x
	 + ($4 || 0)/1000            ## 0 or 0.0n
	 + ($1 || 0)/100, $_                         ## The atomName
	 ]
     } @main;
    
    #print join ' | ', @sorted;
    #print "\n";
    return @sorted;
}

sub notTerminalProtons{
    my ($self,$temp,$bonds) = @_;
    my $N;

    #Cysteine doesnt have /H[123]/
    # the other residues dont have certain Hs
    return 1 if $temp->resName =~ /^[+]?C$/;
    return 1 if $temp->resName =~ /^[+]?A$/ && $temp->atomName =~ /^H[13]$/;
    return 1 if $temp->resName =~ /^[+]?G$/ && $temp->atomName =~ /^H[23]$/;
    return 1 if $temp->resName =~ /^[+]?U$|^[+]?T$/ && $temp->atomName =~ /^H[12]$/;

    foreach my $ch(@{$temp->chainIds}){
	foreach my $a (keys %{$self->{'residues'}{$temp->model}{$ch.$temp->resNumber}}){
	    next if $self->{'all'}{$a}->atomRemote ne $temp->atomRemote #ignoring branch because of H2''
		|| $self->{'all'}{$a}->proton;
	    return 0 if $bonds->checkBond($self->{'all'}{$a}, $temp, '1.2');
	}
    }
    return 1;
}

sub residualAverage{
    my $atom = shift;
    my %hash;
    if(defined $_[0]){
	%hash= %{$_[0]};
	$hash{'x'}=($hash{'x'}+$atom->x)/2;
	$hash{'y'}=($hash{'y'}+$atom->y)/2;
	$hash{'z'}=($hash{'z'}+$atom->z)/2;
    }else{
	$hash{'nc'}=$atom->naturalChain;
	$hash{'x'}=$atom->x;
	$hash{'y'}=$atom->y;
	$hash{'z'}=$atom->z;
	$hash{'r'}='0.00';
    }
    my $tempR = dist($hash{'x'},$atom->x,$hash{'y'},$atom->y,$hash{'z'},$atom->z);
    $hash{'r'}=$tempR unless $hash{'r'} > $tempR;

    return \%hash;
}
1;
