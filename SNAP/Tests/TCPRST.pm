package SNAP::Tests::TCPRST;

use SNAP::Test;	
use vars qw(@ISA $VERSION);
our @ISA = qw(SNAP::Test);	
my $VERSION='1.0';

use strict;

# put any modules you want to use here:
use IO::Socket;
use Time::HiRes qw(gettimeofday tv_interval);

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  if (! defined $self->{timeout}) {
      $self->{timeout} = 10;
  }
  if (! defined $self->{port}) {
      $self->{port} = 1;
  }
  return $self;
}

my %shosts;
my $ltime;
  
sub test {
    my $self = shift;
    $self->logging("starting test") if ($self->debug);
    my $host;
    my @fhosts;
    my @rhosts;
    my $lnow = time % 3600;
    my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
    $ltime = $lnow;
    
    foreach my $cur (split(/[\s+,]+/, $self->{hosts})) {
	my $host;
	my $port;
	my $timeout = undef;
       	my $state;
	my $tBefore;
	my $tDur;

	# the first time through the hash won't be defined.  We don't 
	# want to alarm on each system coming up as it's noisy so we'll
	# presume that it's already up.  If the first poll determines 
	# that it is down it should alert on that anyway.
	
	if (! defined $shosts{$cur}) {
	    $self->logging("Presuming $cur is UP") if ($self->debug);
	    $shosts{$cur} = 'UP';
	    $nag = 'YES'; # it means we're just starting up and $ltime was 0
	}
	
	($host, $port, $timeout) = split(/:/, $cur);
	
	$self->logging("testing: $host") if ($self->debug);
	$tBefore = [gettimeofday];
	my $sock = IO::Socket::INET->new(PeerAddr => $host,
					 PeerPort => ($port || $self->{port}),
					 Proto    => 'tcp',
					 Timeout  => ($timeout || $self->{timeout}),
					 LocalAddr => ($self->{laddr} || '')
					 );
	$tDur = tv_interval($tBefore) || 0;
	if (defined $sock) {
	    # we don't expect the socket to be open,
	    # this is a TCP RST test!
	    $sock->close;
	}

	# Determine if we were down by reset or timeout by looking at the time
	if ($tDur >= ($timeout || $self->{timeout})) {
	    $state = 'DOWN';
	    $self->logging("failed: no connection ".$host.":"
			   .($port || $self->{port}).":"
			   .($timeout || $self->{timeout}).")");
	} else {
	    $state = 'UP';
	    $self->logging("succeeded") if ($self->debug);
	}
	# if we were up, now alert that we're down.  we'll also alert
	# if the $nag flag is set and the state is anything but UP
	
	$self->logging("about to report: host=$host port=$port shosts=$shosts{$cur} state=$state nag=$nag")
	    if ($self->debug);
	
	if (($shosts{$cur} ne $state) || (($nag eq 'YES') && ($state ne 'UP'))) {
	    if ($port != '') {
		push @fhosts, "$host:$port:$state";
		$self->logging("adding: $host:$port:$state") if ($self->debug);
	    } else {
		push @fhosts, "$host:$state";
		$self->logging("adding: $host:$state") if ($self->debug);
	    }
	}
	$shosts{$cur} = $state;
    }

    if ($#fhosts>=0) {
	$self->logging("failed on ".($#fhosts+1)." hosts, returning with error");
	$self->ErrorString('TCP '.(join(', ', @fhosts)).'.');
	return;
    } else {
	$self->logging("returning normally") if ($self->debug);
	return 1;   # test passed
    }
}

1;
