package SNAP::Tests::Selfcheck;   # modify for your package name.
			      # must match SNAP/Tests/file.pm
			      # and [File] in config file must
			      # match, case sensitive.

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.0';

# put any modules you want to use here:

#Don't mess with this unless you know what you're doing.
sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  return $self;
}
  
sub test {
  my $self = shift;
  my $err;
  my $line;
  $self->logging("starting test") if ($self->debug);
  if (-e $self->{lookfor}) {
    $self->logging("found lookfor file") if ($self->debug);
    if (! open(L, $self->{lookfor})) {
      $self->ErrorString("cannot read lookfor file");
      return;
    }
    $line=(<L>);
    close(L);
    if ((unlink($self->{lookfor})) != 1) {
      $err = "can\'t unlink lookfor file";
    }
    if (! open(T, ">".$self->{ackfile})) {
      if (length($err)) {
        $err .= " nor write to ackfile";
      } else {
	$err = "can't write to ackfile";
      }
    }
    print T $line;
    close(T);
    if (length($err)) {
      $self->ErrorString($err) if (length($err));
      return;
    }
  }
  return 1;
}
  
1; # this must be here
