package SNAP::Tests::RocketRaid;

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.1';

# put any modules you want to use here:

my $lastState = 'UP';  # assume the best!

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  if (! defined $self->{cmd}) {
      $self->{cmd} = '/usr/bin/hptraidconf';
  }
  if (! defined $self->{user}) {
      $self->{user} = 'RAID';
  }
  if (! defined $self->{pass}) {
      $self->{pass} = 'hpt';
  }

  $self->logging(ref($self).': Monitoring RAID controller(s) through: '.$self->{cmd}.' as '.$self->{user}.'/<password>');
  return $self;
}
  
sub test {
    my $self = shift;
    my @fhosts;
    my $unitGood = 0;
    my $physicalGood = 0;
    my $totalBad = 0;
    my $gotAction = 0;
    my $lnow = time % 3600;
    my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
    $ltime = $lnow;


    # first off, look at the physical devices

    my $action = $self->{cmd}.' query devices '. $self->{user} .' '.$self->{pass}.' |';
    $self->logging('starting test with: '.$action)
	if ($self->debug);

    open(DMP, "$action");

    while (<DMP>) {
	$gotAction = 1;
	chop;
	my @line;
	(@line) = split();

	if ($line[0] =~ /^Invalid/) {
		$totalBad++;
		push @fhosts, join(' ',@line);
	} elsif ($line[0] =~ /^([1-9]\/[1-9])/) {
	    my $dev = $1;
	    if ($line[6] eq 'NORMAL') {
		$unitGood++;
	    } elsif ($line[6] eq 'SPARE') {
		$unitGood++;
  	    } else {
		$totalBad++;
		push @fhosts, $dev.':'.$line[5];
	    }
	} else {
	    $self->logging('Ignoring line: '. join(' ', @line))
		if (($self->debug) > 3);
	}
    }
    close(DMP);

    # now let's look at the logical devices

    my $action = $self->{cmd}.' query arrays '. $self->{user} .' '.$self->{pass}.' |';
    $self->logging('starting test with: '.$action)
	if ($self->debug);

    open(DMP, "$action");

    while (<DMP>) {
	$gotAction = 1;
	chop;
	my @line;
	(@line) = split();

	if ($line[0] =~ /^Invalid/) {
		$totalBad++;
		push @fhosts, join(' ',@line);
	} elsif ($line[0] =~ /^[1-9]/) {
	    my $dev = $1;
	    if ($line[3] eq 'NORMAL') {
		$unitGood++;
  	    } else {
		$totalBad++;
		push @fhosts, $dev.':'.$line[1];
	    }
	} else {
	    $self->logging('Ignoring line: '. join(' ', @line))
		if (($self->debug) > 3);
	}
    }
    close(DMP);
		
    $state = ((! $gotAction) ? 'DWN' : (($totalBad > 0) ? 'LOW' : 'UP'));
    
    if (($lastState ne $state) || (($nag eq 'YES') && ($state ne 'UP'))) {
	$self->logging('  reporting: ' . $state)
	    if ($self->debug);
	$lastState = $state;
    }

    if ($#fhosts>=0) {
	$self->logging('Failed on '.($#fhosts+1).' devices, returning with error');
	$self->ErrorString('RAID '.(join(', ', @fhosts)).'.');
	return;
    } else {
	$self->logging('returning normally') if ($self->debug);
	return 1;   # test passed
    }
}

1;
