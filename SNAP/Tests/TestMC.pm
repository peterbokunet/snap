package SNAP::Tests::TestMC;   # modify for your package name.
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
  my $time = time();
  my $data = "0036000100110000024C3631373939303132363830321C2430381C343637383031373533333831301C313239391C32323430311C0371";
  my $i, $datb, $conn, $newdata;
  for ($i = 0; $i < length($data); $i+=2) {
    $datb .= pack("C", (hex(substr($data,$i,2))));
  }
  $conn = IO::Socket::INET->new  (PeerPort => $self->{port},
                                PeerAddr => $self->{dest},
                                Proto     => 'tcp');
  if (! $conn) {
    $self->ErrorString("TestMC Failed (no connection ".$self->{dest}.":".$self->{port}.")");
    $self->logging("TestMC Failed (no connection port ".$self->{dest}.":".$self->{port}."), return with error");
    return;
  }
  my $bytes_wrote = syswrite($conn, $datb, length($datb));
  $self->logging("wrote $bytes_wrote bytes") if ($self->debug);
  my $s = IO::Select->new();
  $s->add($conn);
  my @ready = $s->can_read($self->{timeout});
  if (! defined $ready[0]) {
    $self->ErrorString("TestMC Failed (socket closed ".(time()-$time)." sec)");
    $self->logging("TestMC Failed (socket closed ".(time()-$time)." sec) return with error");
    return;
  }
  my $bytes_read = sysread($ready[0], $newdata, 1024);
  $self->logging("read back $bytes_read bytes in ".(time()-$time)." sec") if ($self->debug);
  $self->logging("string read is ".length($newdata)."bytes") if ($self->debug);
  if ($newdata =~/$self->{expect}/) {
    $self->logging("TestMC successful. return normally") if ($self->debug);
    return 1;
  } else {
    $self->ErrorString("TestMC Failed (bad response from MC)");
    $self->logging("TestMC Failed (bad response from MC)");
    $self->logging(xjdump($newdata, length($newdata)));
    return;
  }
}
  
sub xjdump {
  my ($buf, $len) = @_;
  my ($var, $col, $count);
  my ($ret);

  $count = 0;
  while ($count < $len) {
    for ($col = 0; ($count + $col) < $len && $col < 16; $col++) {
      if ($col == 0) {
        $ret .= sprintf "%.4d: ", $count;
      } else {
        if ($col % 4 == 0) {
          $ret .= sprintf " ";
        }
      }
      $var = unpack("C", substr $buf, $count + $col, 1);
      $ret .= sprintf "%02X ", $var
    }
    while ($col++ < 16) {
      if ($col % 4 == 0) {
        $ret .= sprintf " ";
      }
      $ret .= sprintf "   ";
    }
    $ret .= sprintf "  ";
    for ($col = 0; $count + $col < $len && $col < 16; $col++) {
      $var = unpack("C", substr $buf, $count + $col, 1);
      if ($var > 32 && $var < 127) {
        $ret .= sprintf "%c", $var;
      } else {
        $ret .= sprintf ".";
      }
    }
    $ret .= sprintf "\n";
    $count += $col;
  }
  return $ret;
}

1; # this must be here
