package SNAP::Tests::ClamAV;

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
      $self->{port} = 3310;
  }
  $self->logging("Expecting PONG for our PING on $self->{port} from: $self->{dest}");
  return $self;
}
  
sub test {
  my $self = shift;
  my @fhosts;
  $self->logging("starting test") if ($self->debug);
  foreach my $cur (split(/[\s+,]+/, $self->{dest})) {
      my $host;
      my $port;
      ($host, $port) = split(/:/, $cur);
      $self->logging("testing: $host") if ($self->debug);
      my $sock = IO::Socket::INET->new(PeerAddr => $host,
				       PeerPort => ($port || $self->{port}),
				       Proto    => 'tcp',
				       Timeout  => ($self->{timeout} || 10));
      
      if (! defined $sock) {
	  push @fhosts, "$host:" . $port . ":DOWN";
	  $self->logging("ClamAV Failed (no connection ".$host.":".($port || $self->{port}).")");
      } else {
	  my $count, $amt_wrote, $data, $val;
	  my $s = IO::Select->new();
	  $s->add($sock);
	  my $ping = "PING\n";
	  my @ready = $s->can_write($self->{timeout});
	  $amt_wrote = syswrite($ready[0], $ping, length($ping));
	  if ($amt_wrote != length($ping)) {
	      push @fhosts, "$host:0-byte";
	      $self->logging("ClamAV failed, (Wrote $amt_wrote of " . length($ping) . " bytes)") 
		  if ($self->debug);
	  }

	  @ready = $s->can_read($self->{timeout});
	  $amt_read = sysread($ready[0], $data, 512);
	  if ($amt_read == 0) {
	      push @fhosts, "$host:0-byte";
	      $self->logging("ClamAV failed, (No ClamAV PONG received)") if ($self->debug);
	  }
	  if ($data =~ /PONG/) {
	      $self->logging("ClamAV PONG receieved") if ($self->debug);
	  } else {
	      push @fhosts, "$host:garbage";
      	      $self->logging("ClamAV failed, (Got Garbage)") if ($self->debug);
	  }
	  $sock->close;
      }
  }
  if ($#fhosts>=0) {
      $self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
      $self->ErrorString('ClamAV '.(join(', ', @fhosts)).'.');
      return;
  } else {
      $self->logging("returning normally") if ($self->debug);
      return 1;   # test passed
  }
}
1;
