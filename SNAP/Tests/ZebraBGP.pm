package SNAP::Tests::ZebraBGP;

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.1';

# put any modules you want to use here:

my %vhosts;

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  if (! $self->{cmd}) {
      $self->{cmd} = '/usr/pkg/bin/vtysh';
  }
  $self->logging(ref($self).': Monitoring bgpd through: '.$self->{cmd});
  return $self;
}
  
sub test {
    my $self = shift;
    my @fhosts;
    my $action = $self->{cmd}.' -d bgpd -c "show ip bgp summary"'.'|';
    my $lnow = time % 3600;
    my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
    $ltime = $lnow;

    $self->logging('starting test with: '.$action)
	if ($self->debug);

    my $res = open(DMP, "$action");

    while (<DMP>) {
	chop;
	push(@resp, $_);
	
    }
    
    foreach my $cur (split(/[\s+,]+/, $self->{peers})) {
	my $state = -1;
	my ($ip, $tag, $routes) = split(/:/, $cur);
	
	# use the IP as the name, if not provided.
	
	$tag = $ip
	    if ($tag eq '');
	
	$routes = 0
	    if ($routes eq '');
	
	# the first time through the hash won't be defined.  We don't 
	# want to alarm on each system coming up as it's noisy so we'll
	# presume that it's already up.  If the first poll determines 
	# that it is down it should alert on that anyway.
	
	if (! defined $vhosts{$ip}) {
	    $self->logging("Presuming $tag is UP") if ($self->debug);
	    $vhosts{$ip} = 'UP';
            $nag = 'YES'; # it means we're just starting up and $ltime was 0
	}
	
	# because it's valid to have a BGP session with no routes received
	# (perhaps because we're advertising only?) we can't use the case
	# of zero routes as being an error condition.  So we set the state
	# for not being connected to -1.  We can then alert with a proper
	# message below.
	
	foreach $_ ( @resp ) {
	    my @parts = split;
	    $state = $parts[9]
		if (($ip eq $parts[0]) && ($parts[9] =~ /[0-9]+/));
	}
	
	$self->logging($tag . ' is: ' . $state .' routes: ' . $routes . ' alerting: '. (($state == -1) ? 'DWN' : (($state < $routes) ? 'LOW' : 'UP')))
	    if ($self->debug);
	
	$state = (($state == -1) ? 'DWN' : (($state < $routes) ? 'LOW' : 'UP'));
	
	# report the change in state, but only if it takes us below our threshold
	
	if (($vhosts{$ip} ne $state) || (($nag eq 'YES') && ($state ne 'UP'))) {
	    push @fhosts, $tag .':' . $state;
	    $self->logging('  reporting: '. $tag . ': ' . $state)
		if ($self->debug);
	    $vhosts{$ip} = $state;
	}
    }

    if ($#fhosts>=0) {
	$self->logging('Failed on '.($#fhosts+1).' hosts, returning with error');
	$self->ErrorString('BGP '.(join(', ', @fhosts)).'.');
	return;
    } else {
	$self->logging('returning normally') if ($self->debug);
	return 1;   # test passed
    }
}

1;
