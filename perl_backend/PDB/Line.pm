package PDB::Line;

use strict;
use warnings;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};

	$self->{'string'} = $args{'-line'};
	$self->{'model'} = $args{'-model'};
	$self->{'TYPE'} = '';
	$self->{'data'} = '';

	bless $self, $class;

	$self->parse;

	return $self;
}

sub toString{
    my $self=shift;
    if($_[0]){
	print $self->{'string'}."\n" if $self->{'TYPE'} eq $_[0];
    }else{
	print $self->{'string'};
    }
}

sub parse{
    my $self=shift;
    ($self->{'TYPE'},$self->{'data'}) = unpack("A6 A74", $self->{'string'});
}

sub type{my $self=shift; return $self->{'TYPE'};}
sub data{my $self=shift; return $self->{'data'};}
1;
