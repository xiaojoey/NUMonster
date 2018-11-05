package XML::In;
use strict;
use warnings;

use XML::LibXML;

sub new{
    my $class = shift;
    my $self = {};
    my $f = shift;
    if(-e $f){
	$self->{'file'}=$f;
    }else{
	$self->{'string'}=$f;
    }
    $self->{'limits'}=();
    $self->{'pairs'}=();

    $self->{'protons'} = 0;
    
    bless $self, $class;
    $self->parse;
    return $self;
}

sub parse{
    my $self = shift;

    my $parser = XML::LibXML->new();
    my $doc;
    if($self->{'file'}){
	$doc = $parser->parse_file($self->{'file'});
    }else{
	$doc = $parser->parse_string($self->{'string'});
    }

    parseChains($self, $doc);
    parseInfo($self, $doc);
}

sub getEmail{my $self = shift;return $self->{'email'};}
sub getIP{my $self = shift;return $self->{'ip'};}
sub getFile{my $self = shift;return $self->{'file'};}
sub setFile{my $self = shift;$self->{'file'}=$_[0];}
sub getId{my $self = shift;return $self->{'id'};}
sub getProtons{my $self = shift;return $self->{'protons'};}
sub getOS{my $self = shift;return $self->{'os'};}

sub parseChains{
    my ($self, $doc) = @_;
    my ($c1,$c2);

    foreach my $cp($doc->getElementsByTagName("ChainPair")){
	$self->{'pairs'}{$cp->getAttribute("index")}=1;
        $c1 = @{$cp->getChildrenByTagName("Chain")}[0];
        $c2 = @{$cp->getChildrenByTagName("Chain")}[1];

        $self->{'limits'}{$c1->getAttribute("index")}{"start"}=@{$c1->getChildrenByTagName("Start")}[0]->textContent;
        $self->{'limits'}{$c1->getAttribute("index")}{"end"}=@{$c1->getChildrenByTagName("End")}[0]->textContent;
        $self->{'limits'}{$c1->getAttribute("index")}{"chain"}=@{$c1->getChildrenByTagName("Natural")}[0]->textContent;
	if(defined $c1->getAttribute("empty")){
	    $self->{'limits'}{$c1->getAttribute("index")}{"empty"}=1, if $c1->getAttribute("empty") eq "true";
	}

        $self->{'limits'}{$c2->getAttribute("index")}{"start"}=@{$c2->getChildrenByTagName("Start")}[0]->textContent;
        $self->{'limits'}{$c2->getAttribute("index")}{"end"}=@{$c2->getChildrenByTagName("End")}[0]->textContent;
        $self->{'limits'}{$c2->getAttribute("index")}{"chain"}=@{$c2->getChildrenByTagName("Natural")}[0]->textContent;
	if(defined $c2->getAttribute("empty")){
	    $self->{'limits'}{$c2->getAttribute("index")}{"empty"}=1 if $c2->getAttribute("empty") eq "true";
	}
    }
}

sub parseInfo{
    my ($self, $doc) = @_;
    
    my $cps = ${$doc->getElementsByTagName("ChainPairs")}[0];
    $self->{'id'} = $cps->getAttribute("index");
    $self->{'protons'}=1 if $cps->getAttribute("protons") eq "true";

    my $ipNode = ${$doc->getElementsByTagName("IP")}[0];
    $self->{'ip'} = $ipNode->textContent;

    my $emailNode = ${$doc->getElementsByTagName("Email")}[0];
    $self->{'email'} = $emailNode->textContent;

    my $fileNode = ${$doc->getElementsByTagName("File")}[0];
    $self->{'file'} = substr($fileNode->textContent, 31);

    my $osNode = ${$doc->getElementsByTagName("OS")}[0];
    $self->{'os'} = $osNode->textContent;
}

sub getChains{
    my($self,$nc)=@_;
    my @tChs;
    foreach my $ch (keys %{$self->{'limits'}}){
	push @tChs, $ch if $self->{'limits'}{$ch}{'chain'} eq $nc;
    }
    return @tChs;
}

sub start{
    my $self=shift;
    my $ch=shift;
    return $self->{'limits'}{$ch}{'start'};
}

sub naturalChainE{
    my $self = shift;
    return $self->{'limits'}{$_[0]}{'chain'} unless $self->{'limits'}{$_[0]}{'empty'};
    return '';
}

sub end{
    my $self=shift;
    my $ch=shift;
    return $self->{'limits'}{$ch}{'end'};
}

sub web{
    my $self=shift;
    return 1 if %{$self->{'limits'}};
    return 0;
}

sub chains{my $self=shift;return keys %{$self->{'limits'}};}
sub naturalChain{my $self = shift;return $self->{'limits'}{$_[0]}{'chain'};}
sub chainpairs{my $self=shift;return keys %{$self->{'pairs'}};}
1;
