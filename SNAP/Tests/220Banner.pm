package SNAP::Tests::220Banner;

use SNAP::Test;
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.1';

# put any modules you want to use here:
use IO::Socket;
use IO::Select;

my %shosts;
my $ltime;

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;

  return $self;
}
  
sub test {
  my $self = shift;
  my @fhosts;
  my $lnow = time % 3600;
  my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
  $ltime = $lnow;

  $self->logging("starting test") if ($self->debug);
  foreach my $cur (split(/[\s+,]+/, $self->{dest})) {
    $self->logging("testing: $host") if ($self->debug);
    my $host;
    my $port;
    my $state;

    # the first time through the hash won't be defined.  We don't 
    # want to alarm on each system coming up as it's noisy so we'll
    # presume that it's already up.  If the first poll determines 
    # that it is down it should alert on that anyway.

    if (! defined $shosts{$cur}) {
      $self->logging("Presuming $cur is UP") if ($self->debug);
      $shosts{$cur} = 'UP';
      $nag = 'YES'; # it means we're just starting up and $ltime was 0
    }

    ($host, $port) = split(/:/, $cur);

    if (! ($port || $self->{port})) {
      $self->logging('Error with config.  Cannot find a port to test.');
      return 0;
    }

    if (! $host) {
      $self->logging('Error with config.  Cannot find a host to test.');
      return 0;
    }

    my $sock = IO::Socket::INET->new(PeerAddr => $host,
				     PeerPort => ($port || $self->{port}),
				     Proto    => 'tcp',
				     Timeout  => ($self->{timeout} || 10),
				     LocalAddr => ($self->{laddr} || ''),
				     );
      
    if (! defined $sock) {
      $state = 'DOWN';
      $self->logging("Failed (no connection ".$host.":".($port || $self->{port}).")");
    } else {
      my $count, $amt_read, $data, $val;
      my $s = IO::Select->new();
      $s->add($sock);
      my @ready = $s->can_read($self->{timeout});
      $amt_read = sysread($ready[0], $data, 512);
      if ($amt_read == 0) {
	$state = '0-byte';
	$self->logging("Failed, (No 220 received)")
	  if ($self->debug);
      }
      if ($data =~ /220/) {
	$state = 'UP';
	$self->logging("220 receieved")
	  if ($self->debug);
      } else {
	$state = 'garbage';
	$self->logging('Failed, (Got Garbage: '.$data.')')
	  if ($self->debug);
      }
      $sock->close;
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
    my $pkg = (split(/::/, ref($self)))[$#_];
    $self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
    $self->ErrorString($pkg.' '.(join(', ', @fhosts)).'.');
    return;
  } else {
    $self->logging("returning normally") if ($self->debug);
    return 1;   # test passed
  }
}
1;
