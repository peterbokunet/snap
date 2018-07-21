package SNAP::Tests::VPNSSH;

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.1';

# put any modules you want to use here:
use IO::Socket;
use IO::Select;

my $ltime = 0;
my %vhosts;

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;

  $self->{port} = 22
    if (! $self->{port});

  $self->logging('Resetting VPN peers at '.$self->{peer}.' on '
		 .$self->{vport}.' for: '.$self->{dest}.' over a VPN');
  return $self;
}
  
sub test {
  my $self = shift;
  my @fhosts;
  my $lnow = time % 3600;
  my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
  $ltime = $lnow;

  $self->logging('->test()')
    if ($self->debug);

  foreach my $cur (split(/[\s+,]+/, $self->{dest})) {
    my $host;
    my $port;
    my $state;
    my $cycles;
    ($host, $cycles, $port) = split(/:/, $cur);
    $cycles = 6
      if ($cycles eq '');
    if (! defined $vhosts{$host}) {
      $self->logging("Presuming $cur is UP") if ($self->debug);
      $vhosts{$cur} = 'UP';
      $vhosts{"$cur cycles"} = $cycles;
    }
      
    my $sock = IO::Socket::INET->new(PeerAddr => $host,
				     PeerPort => ($port || $self->{port}),
				     Proto    => 'tcp',
				     Timeout  => ($self->{timeout} || 10),
				     LocalAddr => ($self->{laddr} || ''),
				     );
      
    if (! defined $sock) {
      $self->logging("Failed (no connection ".$host.":".($port || $self->{port}).")");
      # at this point we know we're not UP.
      # the only thing we know is that we're DWN
	  
      $state = 'DWN';
	
      # increment cycles
      $vhosts{"$cur cycles"}++;
      $self->logging('Cycles for '.$cur.' is now: '. $vhosts{"$cur cycles"})
        if ($self->debug > 9);
	  
	  
      if ($vhosts{"$cur cycles"} > $cycles) {
	# We don't want to pound on racoon, so we'll only reset the
	# peer every so often.  The 'cycles' paramter let's us manage
        # our way through this.  Some peers do need to be unstuck at
        # times.
        $self->resetpeer($host);
        $state = 'RST';
        $vhosts{"$cur cycles"} = 0;
      }

    } else {
      $state = 'UP';
      $vhosts{"$cur cycles"} = $cycles;
      $sock->close;
    }
      
    $self->logging("about to report: host=$host port=$port vhosts=$vhosts{$cur} state=$state nag=$nag cycles=".$vhosts{"$cur cycles"})
      if ($self->debug);
      
    if ($state ne 'RST') {

      # don't alert anything, regardless if it's UP or DWN
      # we're in this limbo land where we might be back up or
      # might still be down

      if (($vhosts{$cur} ne $state) || (($nag eq 'YES') && ($state ne 'UP'))) {
	      
        # we have a new state (meaning it's UP or DWN) 
        # or it's time to nag
	      
        if ($port != '') {
          push @fhosts, "$host:$port:$state";
	  $self->logging('adding: '.$host.':'.$port.':'.$state)
	    if ($self->debug);
        } else {
          push @fhosts, "$host:$state";
          $self->logging('adding: '.$host.':'.$state)
            if ($self->debug);
        }
      }
      $vhosts{$cur} = $state;
    }
  }
  
  if ($#fhosts>=0) {
    $self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
    $self->ErrorString('VPNSSH '.(join(', ', @fhosts)).'.');
    return;
  } else {
    $self->logging("returning normally") if ($self->debug);
    return 1;   # test passed
  }
}

sub resetpeer {
  my $self = shift;
  my $peer = shift;

  $self->logging('->resetpeer('.$peer.')');

  if ((defined $peer) && ($peer != '')) {
    return $self;
  }

  $self->logging('creating sock: '.$self->{peer}.':'.$self->{vport})
    if ($self->debug>2);
  my $sock = new IO::Socket::INET ( 
				    PeerAddr => $self->{peer}, 
				    PeerPort => $self->{vport}, 
				    Proto => 'tcp', 
				    Timeout  => 10);

  if (defined $sock) { 
    $self->logging('connected')
      if ($self->debug>3);
    select($sock); $| = 1;
    $self->logging('selected')
      if ($self->debug>3);
    print $sock "$peer\n"; 
    $self->logging('printed')
      if ($self->debug>3);
    sleep(2);
    $self->logging('slept')
      if ($self->debug>3);
    close($sock);
    $self->logging('closed')
      if ($self->debug>3);
  } else {
    $self->logging('Failed to connect to: '.$self->{peer}.':'.$self->{vport});
  }
  return $self;
}

1;
