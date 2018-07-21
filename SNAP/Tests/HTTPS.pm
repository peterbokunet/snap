package SNAP::Tests::HTTPS;

use SNAP::Test;	      # parent app.
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
      $self->{port} = 443;
  }
  $self->logging("Expecting \'HTTP/1.1 400 Bad Request\' on $self->{port} from: $self->{dest}");
  return $self;
}
  
sub test {
  my $self = shift;
  my @fhosts;
  $self->logging("starting test") if ($self->{_DEBUG});
  foreach my $cur (split(/[\s+,]+/, $self->{dest})) {
      $self->logging("testing: $cur") if ($self->{_DEBUG});
      my $host;
      my $port;
      ($host, $port) = split(/:/, $cur);
      my $sock = IO::Socket::INET->new(PeerAddr => $host,
				       PeerPort => ($port || $self->{port}),
				       Proto    => 'tcp',
				       Timeout  => ($self->{timeout} || 10),
				       LocalAddr => ($self->{laddr} || '')
				       );
      
      if (! defined $sock) {
	  push @fhosts, "$host:" . $port . ":DOWN";
	  $self->logging("HTTPS Failed (no connection ".$host.":".($port || $self->{port}).")");
      } else {
	  my $count, $amt_read, $data, $val;
	  my $s = IO::Select->new();
	  $s->add($sock);
	  my @ready = $s->can_write($self->{timeout});
	  syswrite($ready[0], "HEAD / HTTP/1.0\r\n\r\n");
	  @ready = $s->can_read($self->{timeout});
	  $amt_read = sysread($ready[0], $data, 512);
	  if ($amt_read == 0) {
	      push @fhosts, "$host:0-byte";
	      $self->logging("HTTPS failed, (No HTTP received)") if ($self->{_DEBUG});
	  } else {
	      if ($data =~ /HTTP\/1.1 400 Bad Request/) {
		  $self->logging("HTTP receieved") if ($self->{_DEBUG});
	      } else {
		  push @fhosts, "$host:garbage";
		  $self->logging("HTTPS failed, (Got Garbage)") if ($self->{_DEBUG});
	      }
	  }
	  $sock->close;
      }
  }
  if ($#fhosts>=0) {
      $self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
      $self->ErrorString('HTTPS '.(join(', ', @fhosts)).'.');
      return;
  } else {
      $self->logging("returning normally") if ($self->{_DEBUG});
      return 1;   # test passed
  }
}
1;
