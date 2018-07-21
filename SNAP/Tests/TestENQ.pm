package SNAP::Tests::TestENQ;   # modify for your package name.
			      # must match SNAP/Tests/file.pm
			      # and [File] in config file must
			      # match, case sensitive.

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.0';

# put any modules you want to use here:
use IO::Socket;
use IO::Select;

#Don't mess with this unless you know what you're doing.
sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  return $self;
}
  
sub test {
  my $self = shift;
  $self->logging("starting test") if ($self->debug);
  my $sock = IO::Socket::INET->new(PeerAddr => $self->{dest},
                              PeerPort => $self->{port},
                              Proto    => 'tcp');

  if (! defined $sock) {
    $self->ErrorString("TestENQ Failed (no connection ".$self->{dest}.":".$self->{port}.")");
    $self->logging("TestENQ Failed (no connection ".$self->{dest}.":".$self->{port}.")");
    return;
  }

  my $enqcount = 0;
  my $count, $amt_read, $data, $val;
  my $s = IO::Select->new();
  $s->add($sock);
  my @ready = $s->can_read($self->{timeout});
  for ($count=1; $count <5; $count++) {
    if (! defined $ready[0]) {
      $self->ErrorString("TestENQ Failed (timed out, socket closed)");
      $self->logging("TestENQ Failed (timed out, socket closed)") if ($self->debug);
      return;
    }
    $amt_read = sysread($ready[0], $data, 512);
    if ($amt_read == 0) {
      $self->ErrorString("TestENQ failed, (No ENQ received, 0-byte)");
      $self->logging("TestENQ failed, (No ENQ received)") if ($self->debug);
      return;
    }
    $val = unpack("C", $data);
    if ($val eq "5") {
      $enqcount++;
    } else {
      $self->ErrorString("TestENQ failed, (Got Garbage)");
      $self->logging("TestENQ failed, (Got Garbage)") if ($self->debug);
      return;
    }
  }
  $sock->close;
  if ($enqcount != 4) {
    $self->ErrorString("$enqcount of 4 ENQs receieved");
    $self->logging("$enqcount of 4 ENQs receieved") if ($self->debug);
    return;
  } else {
    $self->logging("$enqcount of 4 ENQs receieved") if ($self->debug);
    return 1;
  }
}
  
1; # this must be here
