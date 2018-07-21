package SNAP::Tests::SMTP;

use SNAP::Tests::220Banner;
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Tests::220Banner);
$VERSION='1.1';

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;

  $self->{port} = 25
    if (! $self->{port});

  $self->logging("Expecting 220 Banner on $self->{port} from: $self->{dest}");
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
	  $self->logging("SMTP Failed (no connection ".$host.":".($port || $self->{port}).")");
      } else {
	  my ($count, $amt_read, $data, $val);
	  my $s = IO::Select->new();
	  $s->add($sock);
	  my @ready = $s->can_read($self->{timeout});
	  $amt_read = sysread($ready[0], $data, 512);
	  if ($amt_read == 0) {
	      push @fhosts, "$host:0-byte";
	      $self->logging("SMTP failed, (No SMTP Banner received)") if ($self->debug);
	  }
	  if ($data =~ /^(\d\d\d) /) {
	      $self->logging("SMTP receieved " . $data) if ($self->debug);
	  } else {
	      push @fhosts, "$host:garbage";
      	      $self->logging("SMTP failed, (Got Garbage)") if ($self->debug);
	  }
	  $sock->close;
      }
  }
  if ($#fhosts>=0) {
      $self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
      $self->ErrorString('SMTP '.(join(', ', @fhosts)).'.');
      return;
  } else {
      $self->logging("returning normally") if ($self->debug);
      return 1;   # test passed
  }
}

