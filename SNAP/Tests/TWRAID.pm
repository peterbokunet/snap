package SNAP::Tests::TWRAID;

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
      $self->{cmd} = '/root/bin/tw_cli';
  }
  if (! defined $self->{ctlrs}) {
      $self->{ctlrs} = 'c0';
  }
  $self->logging(ref($self).': Monitoring RAID controller(s) ['. $self->{ctlrs} .'] through: '.$self->{cmd});
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

    foreach my $ctlr (split(/[\s+,]+/, $self->{ctlrs})) {
	my $action = $self->{cmd}.' info '. $ctlr .'|';
	$self->logging('starting test with: '.$action)
	    if ($self->debug);

	open(DMP, "$action");

	while (<DMP>) {
	    $gotAction = 1;
	    chop;
	    my @line;
	    (@line) = split();
	    if ($line[0] =~ /^u/) {
		$self->logging($line[0].' is: '.$line[2])
		    if (($self->debug) > 3);
		# logical unit
		if ($line[2] eq 'OK') {
		    $unitGood++;
		} elsif ($line[2] eq 'VERIFYING') {
		    $unitGood++;
		} else {
		    push @fhosts, '/'.$ctlr.'/'.$line[0].':'.$line[2].' ('.$line[1].')';
		    $totalBad++;
		}
	    } elsif ($line[0] =~ /^p/) {
		$self->logging($line[0].' is: '.$line[1])
		    if (($self->debug) > 3);
		# physical device
		if ($line[1] eq 'OK') {
		    $physicalGood++;
		} else {
		    push @fhosts, '/'.$ctlr.'/'.$line[0].':'.$line[1].')';
		    $totalBad++;
		}
	    } elsif ($line[0] =~ /^Error/) {
		# the command logged a significant error
		$self->logging(join(' ', @line));
		push @fhosts, 'Error';
		$totalBad++;
	    } else {
		$self->logging('Ignoring line: '. join(' ', @line))
		    if (($self->debug) > 3);
	    }
	}
    }
	
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
