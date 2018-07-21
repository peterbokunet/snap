package SNAP::Tests::Span;

use SNAP::Test;
use vars qw(@ISA $VERSION);
our @ISA = qw(SNAP::Test);	
my $VERSION='1.2';

use strict;

my $ltime = 0;
my %vspans;

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;

    if (! defined $self->{app}) {
	$self->{app} = '/usr/sbin/asterisk';
    }
    if (! defined $self->{args}) {
	$self->{args} = '-rx';
    }
    if (! defined $self->{cmd}) {
	$self->{cmd} = 'zap show status';
    }

    if (! -x $self->{app}) {
	$self->logging("Unable to execute: $self->{app}. Disabling.");
	return undef;
    }

    $self->command($self->{app}.' '.$self->{args}.' "'.$self->{cmd}.'"');
    return $self;
}

sub command {
    my ($self) = shift;
    $self->{command} = shift if (@_);
    $self->logging(ref($self).'->command = '.$self->{command})
	if ($self->debug>2);
    return $self->{command};
}

sub test {
    my $self = shift;
    my @fhosts;
    my @ignores;

    $self->logging('->test()')
	if ($self->debug);

    my $lnow = time % 3600;
    my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
    $ltime = $lnow;

    open(RES, $self->command()."|");

    @ignores = split(/[\s+,]+/, $self->{ignore});

    while (<RES>) {
	chop;
	my $line = $_;
	my $card;
	my $span;
	my $state;

	$self->logging('Read line: ' . $line)
	    if ($self->debug > 3);

	if ($line =~ /Card (\d+) Span (\d+)(\s+)(\w+)/) {
	    $card = $1;
	    $span = $2;
	    $state = $4;

	    if (grep { $ignores[$_] eq "$card/$span" } 0..$#ignores) {
		$self->logging('Ignoring: Card '.$card.' Span '.$span.': '.$state)
		if ($self->debug > 2);
	    } else {
		$self->logging('Read status: Card '.$card.' Span '.$span.': '.$state)
		    if ($self->debug > 1);
		
		if (! defined $vspans{"$card/$span"}) {
		    $self->logging("Presuming $card $span is OK")
			if ($self->debug);
		    $vspans{"$card/$span"} = 'OK';
		}
		
		if ($state ne $vspans{"$card/$span"}) {
		    $self->logging("Card $card Span $span: $state")
			if ($self->debug);
		    push @fhosts, "$card/$span:$state";
		    $vspans{"$card/$span"} = $state;
		} else {
		    push @fhosts, "$card/$span:$state"
			if (($state ne 'OK') && ($nag eq 'YES'));
		}
	    }
	}
    }

    if ($#fhosts>=0) {
	$self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
	$self->ErrorString('Span '.(join(', ', @fhosts)).'.');
	return;
    } else {
	$self->logging("returning normally") if ($self->debug);
	return 1;   # test passed
    }
}

1; # this must be here

