package SNAP::Tests::ICA;

use SNAP::Test;
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.1';

# put any modules you want to use here:
use IO::Socket;
use IO::Select;

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  if (! $self->{port}) {
      $self->{port} = 1494;
  }
  $self->logging("Expecting ICA on $self->{port} from: $self->{dest}");
  return $self;
}
  
my %shosts;
my $ltime;

sub test {
  my $self = shift;
  my @fhosts;
  $self->logging("starting test") if ($self->debug);
  foreach my $cur (split(/[\s+,]+/, $self->{dest})) {
      my $host;
      my $port;
      
      my $lnow = time % 3600;
      my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
      $ltime = $lnow;
      
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
      $self->logging("testing: $host") if ($self->debug);
      my $sock = IO::Socket::INET->new(PeerAddr => $host,
				       PeerPort => ($port || $self->{port}),
				       Proto    => 'tcp',
				       Timeout  => ($self->{timeout} || 10),
				       LocalAddr => ($self->{laddr} || '')
				       );
      
      if (! defined $sock) {
	  $state = 'DOWN';
	  $self->logging("ICA Failed: no connection ".$host.":".($port || $self->{port}).")");
      } else {
	  my $count, $amt_read, $data, $val;
	  my $s = IO::Select->new();
	  $s->add($sock);
	  my @ready = $s->can_read($self->{timeout});
	  $amt_read = sysread($ready[0], $data, 512);
	  if ($amt_read == 0) {
	      $state = "$host:0-byte";
	      $self->logging("ICA failed: 0-byte read");
	  } elsif ($data =~ /ICA/) {
	      $state = 'UP';
	      $self->logging("passed ($host)") if ($self->debug);
	  } else {
	      $state = 'garbage';
	      $self->logging("ICA failed: Got Garbage on socket");
	  }
	  $sock->close;
      }
  }

  # if we were up, now alert that we're down.  we'll also alert
  # if the $nag flag is set and the state is anything but UP

  $self->logging("about to report: host=$host shosts=$shosts{$cur} state=$state nag=$nag")
      if ($self->debug);

  if (($shosts{$cur} ne $state) || (($nag eq 'YES') && ($state ne 'UP'))) {
    push @fhosts, "$host:$state";
    $self->logging("adding: $host:$state") if ($self->debug);
  }
  $shosts{$cur} = $state;

  if ($#fhosts>=0) {
    $self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
    $self->ErrorString('ICA '.(join(', ', @fhosts)).'.');
    return;
  } else {
    $self->logging("returning normally") if ($self->debug);
    return 1;   # test passed
  }
}
1; # this must be here
