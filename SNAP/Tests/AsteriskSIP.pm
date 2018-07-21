package SNAP::Tests::AsteriskSIP;

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
      $self->{cmd} = '/usr/sbin/asterisk';
  }
  $self->logging(ref($self).': Monitoring asterisk through: '.$self->{cmd}.' for '.$self->{peers}.' peers');
  return $self;
}
  
sub test {
    my $self = shift;
    my @fhosts;
    my $action = $self->{cmd}.' -rx "sip show peers"'.'|';
    my $totalup = 0;
    my $totaldown = 0;
    my $gotAction = 0;
    my $lnow = time % 3600;
    my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
    $ltime = $lnow;

    $self->logging('starting test with: '.$action)
	if ($self->debug);

    open(DMP, "$action");

    while (<DMP>) {
	$gotAction = 1;
	chop;
	my @line;
	(@line) = split();
	$totalup++
	    if ($line[5] eq 'OK');
	$totaldown++
	    if ($line[5] eq 'UNKNOWN');
	
	$self->logging($line[0].' is: '.$line[5].'; '.$totalup.'/'.$totaldown.'/'.($totalup+$totaldown))
	    if (($self->debug) > 3);
    }
    
    $self->logging('Total up: '.$totalup.'; alert at: '.$self->{peers})
	if ($self->debug);
    
    $state = ((! $gotAction) ? 'DWN' : (($totalup < $self->{peers}) ? 'LOW' : 'UP'));
    
    # report the change in state, but only if it takes us below our threshold
    
    if (($lastState ne $state) || (($nag eq 'YES') && ($state ne 'UP'))) {
	push @fhosts, $tag .':' . $totalup . ':' . $state;
	$self->logging('  reporting: '. $totalup . ': ' . $state)
	    if ($self->debug);
	$lastState = $state;
    }

    if ($#fhosts>=0) {
	$self->logging('Failed on '.($#fhosts+1).' hosts, returning with error');
	$self->ErrorString('SIP '.(join(', ', @fhosts)).'.');
	return;
    } else {
	$self->logging('returning normally') if ($self->debug);
	return 1;   # test passed
    }
}

1;
