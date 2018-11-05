package WebDBI;
use strict;
use warnings;

use DBI;

my $dbh;
my $dbi = "DBI:mysql:database=monster;host=localhost";
my $u = "monster_web";
my $p = "m0n5tw3b";

sub init{
    my $self = shift;
    my $d = getDate();
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    my $i = '';
    my $os = $dbh->quote($_[4]);
    $i = $dbh->do("INSERT INTO job (id, file, ip, email, os) VALUES ('$_[0]', '$_[1]', '$_[2]', '$_[3]', $os)") unless $_[0] eq 'test';
    $i = $dbh->do("UPDATE job SET file='$_[1]', ip='$_[2]', email='$_[3]', os=$os WHERE id='$_[0]'") if $_[0] eq 'test';
    $dbh->disconnect();
    return $i;
}

sub start{
    my $self = shift;
    my $d = getDate();
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    my $pr = $_[1]->getProtons;
    my $i = '';
    $i = $dbh->do("UPDATE job SET start='$d',protons='$pr' WHERE id='$_[0]'");
    $i = $dbh->do("INSERT INTO scrutiny_web (id, start) VALUES ('$_[0]', '$d' )") unless $_[0] eq 'test';
    $i = $dbh->do("UPDATE scrutiny_web SET start='$d' WHERE id='$_[0]'") if $_[0] eq 'test';
    $dbh->disconnect();
}

sub whatif{
    my $self = shift;
    my $d = getDate();
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    my $i = '';
    $i = $dbh->do("UPDATE scrutiny_web SET whatif='$d' WHERE id='$_[0]'");
    $dbh->disconnect();
}

sub parse{
    my $self = shift;
    my $j = shift;
    my $m = shift;
    my @chains = @_;
    my $c = join ',',@chains;
    my $d = getDate();
    my $i = '';
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    $i = $dbh->do("UPDATE scrutiny_web SET models='$m', chains='$c', parse='$d' WHERE id='$j'");
    $dbh->disconnect();
}

sub set_model{
    my $self = shift;
    my $i = '';
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    $i = $dbh->do("INSERT INTO scrutiny_web_model (id, model, cp) VALUES ('$_[0]', '$_[1]', '$_[2]')") unless $_[0] eq 'test';
    $dbh->disconnect();
}

sub set_time{
    my $self = shift;
    my $d = getDate();
    my $i = '';
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    $i = $dbh->do("UPDATE scrutiny_web_model SET $_[3]='$d' WHERE id='$_[0]' AND model='$_[1]' AND cp='$_[2]' ");
    $dbh->disconnect();
}

sub result{
    my $self = shift;
    my $j = shift;
    my $m = shift;
    my $cp = shift;
    my $r = shift;
    my $i = -e $r;
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    $i = $dbh->do("UPDATE scrutiny_web_model SET result='$i' WHERE id='$j' AND model='$m' AND cp='$cp' ");
    $dbh->disconnect();
}

sub naming_error{
    my $self = shift;
    my $x = shift;
    my $a = shift;
    my $m = shift;
    my $a1 = $a->atomName();
    my $a2;
    my $bool=0;
    my $f=$x->getFile();
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    my $sth = $dbh->prepare("SELECT atom FROM atom_error WHERE PdbJob='$f'");
    $sth->execute();
    $sth->bind_columns( undef, \$a2);
    while($sth->fetch()){
	$bool=1 if $a2 eq $a1;
	last if $bool;
    }
    unless($bool){
	$dbh->do("INSERT INTO atom_error (PdbJob, idtype, method, atom) VALUES ('$f', 'file', '$m', '$a1')");
    }

    $sth->finish();
    $dbh->disconnect();
}

sub print{
    my $self = shift;
    my $d = getDate();
    my $i = '';
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    $i = $dbh->do("UPDATE scrutiny_web SET print_models='$d' WHERE id='$_[0]'");
    $dbh->disconnect();
}

sub end{
    my $self = shift;
    my $d = getDate();
    my $dbh = DBI->connect($dbi,$u,$p,{'RaiseError' => 1});
    my $i = $dbh->do("UPDATE job SET end='$d' WHERE id='$_[0]'");
    $dbh->disconnect();
    return $i;
}

sub getDate{
    my $d = `date +'%Y-%m-%d %H:%M:%S'`;
    return $d;
}
###############################################################
#Return the Job IDs in accordance to its success value
###############################################################
#Format: successID([0,1])
###############################################################
sub successID{

    my $self = shift;
    my @id;
    my $i = $_[0];
    #returning successful job IDs if 1, failed job IDs if 0
    
    my $sth = $dbh->prepare("SELECT id from job WHERE success = ?");
    $sth->execute($i);
    #prepare the selected data

    $i = 0;	
    while(my @dummy = $sth->fetchrow_array()) {
	$id[$i++] = $dummy[0]; 
    }
    if ($sth->rows == 0) {
	#fail value
	return undef;
    }
    $sth->finish;
    return @id;
}
 
###############################################################
#Format: ridID(table,id)
#id is PDB ID to be deleted (can be array or scalar)
###############################################################   
sub ridID{
    my $self = shift;
    my $tablename = shift;
    my @ids = @_;
    foreach my $bad (@ids){
	$dbh->do("DELETE from $tablename WHERE id = '$bad'");
    }
    return 1;
}    

#####################################################################
# Format of the function:
# database->search(table [,category=>what to match])
# will take many arguments as assigned (will also take 1 argument
# of course, that will lead to an error if there are more 
# categories than the actual data.)
#####################################################################
sub search{
    my $self = shift;
    my $tablename = shift;
    my %hasharg = @_;
    my $i = $#_;
    my $text = " ";
    $i = ($i+1)/2;  #how many arguments were taken
    my $sth;
    if($i == 0){
	$sth = $dbh->prepare("SELECT * from $tablename");
	$sth->execute();
    }
    else{
	foreach my $key (keys %hasharg)
	{
	    $text .= " $key = \"$hasharg{\"$key\"}\"";
	    $i--;
	    if($i>0){
		$text .= " and";
	    }
	}
	$sth = $dbh->prepare("SELECT * from $tablename WHERE $text");
	$sth->execute();
    }
    my @data;
    $i = 0;

    while(my @dummy = $sth->fetchrow_array())
	{
	    $data[$i++] = \@dummy;
	}
    $sth->finish();	
    if(($#data+1) ==  0){
	return 1;
    }
    return @data;
}
##########################################################
#Specialized function to remove Email before certain week
##########################################################
#Format: rmOldEmail(Email, how many weeks ago)
##########################################################
sub rmOldEmail{
    my $self = shift;
    my $Email = shift;
    my @current = localtime(time()-60*60*24*7*$_);
    $current[4]++;
    $current[5]+=1900;
    $current[4] = sprintf("%02d",$current[4]);
    $current[3] = sprintf("%02d",$current[3]);
    $current[2] = sprintf("%02d",$current[2]);
    $current[1] = sprintf("%02d",$current[1]);
    $current[0] = sprintf("%02d",$current[0]);
    
    my $time =  "$current[5]-$current[4]-$current[3] $current[2]:$current[1]:$current[0]";
    my $sth = $dbh->prepare("SELECT id from web WHERE time < $time and email = ?");
    $sth->execute($Email);
    my @id;
    while(my @dummy = $sth.fetchrow_array()){
	push(@id,$dummy[0]);
    }
    if($#id < 0){
	return 1; #fail
    }
    return @id;


}
##########################################
#Add new PDB to scrutiny table
##########################################
#Format: AddnewPDB(pdb) automatically set NULL value to scrutiny
##########################################
sub AddnewPDB{
    my $self = shift;
    my $id = shift; 
    $dbh->do("DELETE from scrutiny WHERE id = '$id'");	
    return $dbh->do("INSERT INTO scrutiny VALUES ('$id',NULL)");
}
###########################################
#Obtain a list of scrutinized data
###########################################
#Format: scrutinise(pdb, value[0,1]
# 0 -> NULL 
# 1 -> NOT NULL
###########################################
sub scrutinised{
    if($#_ == 0){ return undef; } 
    my $self = shift;
    my $sth;
    if($_[0] == 0){
	$sth = $dbh->prepare("SELECT * from scrutiny where result is NULL");
    }
    elsif($_[0] == 1){
	$sth = $dbh->prepare("SELECT * from scrutiny where result is NOT NULL");
    }
    else{ return undef; }
    $sth->execute();
    my @data;
    my $i = 0;
    
    while(my @dummy = $sth->fetchrow_array())
    {
	$data[$i++] = $dummy[0];
    }
    $sth->finish();	
    
    if(($#data+1) ==  0){
	return undef;
    }
    return @data;
}
############################################
#Assign a value to Scrutiny table
############################################
#Format: assignScru(pdb, value[0,1,2,3])
# 0 -> failed the scrutinized
# 1 -> pass the scrutinized
# 2 -> successfully ran by MONSTER
# 3 -> pass the scrutinized but failed in MONSTER
############################################

sub assignScru{
    if($#_ != 2 || $_[2] > 3){ return 1; }
    #Fail to have 3 arguments or last argument is not 3 , 2, 1 or 0
    
    my $class = shift;
    my $pdb = shift;
    my $value = shift;

    $dbh->do("UPDATE scrutiny SET result = '$value' where id = '$pdb'");
    return 0;
}

#############################################
#Add new row to Bond table
#############################################
#Format: addBond(pdb,cp [,"col"=>"data"...])
#############################################
sub addBond{
    if(($#_ < 2)||($#_>12)){ return 1; } #The number of the arguments exceeds the columns
    my $self = shift;
    my $pdb = shift;
    my $cp = shift;
    my %hash = @_ unless ($#_+1) == 0;
    my $colname = "(pdb,cp"; my $coldata = "('$pdb','$cp'";
    if($#_ >= 0){ 
	foreach (keys %hash){
	    my ($coln, $cold) = ($_, $hash{$_});
	    if($cold){  #If the input argument is inappropriate
		$coldata .= ",'$cold'"; 
		$colname .= ",$coln";
	    }
	}
    }
	$colname .= ")";
	$coldata .= ")";
    #Delete before update to solve the problem where the bond already exists
    $dbh->do("DELETE from bond WHERE pdb = '$pdb' AND cp = '$cp'");
    $dbh->do("INSERT into bond $colname VALUES $coldata") or die "ERROR WITH addBOND: $!";
    return 0;
}

#############################################
#Add new row to Atom table
#############################################
#Format: addAtom(pdb,cp [,col=>data...])
#############################################
sub addAtom{
    if(($#_ < 2)||($#_>11)){ return 1; } #The number of the arguments exceeds the columns
    my $self = shift;
    my $pdb = shift;
    my $cp = shift;
    my %hash = @_ unless ($#_+1) == 0;
    my $colname = "(pdb,cp"; my $coldata = "('$pdb','$cp'";
    if($#_ >= 0){ 
	foreach (keys %hash){
	    my $coln = $_;
	    my $cold = $hash{$_};
	    if($cold){  #If the input argument is inappropriate
		$coldata .= ",'$cold'"; 
		$colname .= ",$coln";
	    }
	}
    }
	$colname .= ")";
	$coldata .= ")";
    #Delete before update to solve the problem where the bond already exists
    $dbh->do("DELETE from atom WHERE pdb = '$pdb' AND cp = '$cp'");
    $dbh->do("INSERT into atom $colname VALUES $coldata") or die "ERROR WITH addAtom: $!";
    return 0;
}
#############################################
#Update bond data
#############################################
#Format: editBond(pdb,cp [,"col"=>"data"...])
#############################################
sub editBond{
    if(($#_ < 3)||($#_ > 12)){ return 1; }
    my $self = shift;
    my $pdb = shift;
    my $cp = shift;
    my %hash = @_ unless ($#_+1) == 0;
    my $colname = "";
    my $coldata = "pdb = '$pdb' AND cp = '$cp'";
    foreach(keys %hash){
	my $coln = $_;
	my $cold = $hash{$_} unless !$hash{$_};
	if($cold){
	    $colname .= "$coln = '$cold',";
	}
    }
    chop $colname; #Get rid of the last comma
    $dbh->do("UPDATE bond SET $colname WHERE $coldata")
	or die "ERROR WITH editBOND: $!";
    return 0;
}
############################################
#Update atom data
############################################
#Format: editAtom(pdb,cp [,"col"=>"data"...])
############################################
sub editAtom{
    if(($#_ < 3)||($#_ > 11)){ return 1; }
    my $self = shift;
    my $pdb = shift;
    my $cp = shift;
    my %hash = @_ unless ($#_+1) == 0;
    my $colname = "";
    my $coldata = "pdb = '$pdb' AND cp = '$cp'";
    foreach(keys %hash){
	my $coln = $_;
	my $cold = $hash{$_} unless !$hash{$_};
	if($cold){
	    $colname .= "$coln = '$cold',";
	}
    }
    chop $colname; #Get rid of the last comma
    $dbh->do("UPDATE atom SET $colname WHERE $coldata")
	or die "ERROR WITH editAtom: $!";
    return 0;
}
1;
