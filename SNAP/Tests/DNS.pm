package SNAP::Tests::DNS;
use SNAP::Test;
use vars qw(@ISA $VERSION);
our @ISA = qw(SNAP::Test);	
my $VERSION='1.0';
my $command = "unset";

use strict;

# put any modules you want to use here:


sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  if ($self->{format} eq 'nslookup') {
    $self->logging("Setting command format to: nslookup") if ($self->debug);
  } else {
    $self->logging("Setting command format to: dig") if ($self->debug);
  }
  $command = $self->{command};
  $self->logging("Setting command to \"$command\"") if ($self->debug);
  return $self;
}
  
sub test {
  my $self = shift;
  $self->logging("starting test") if ($self->debug);
  my $res;
  my $host;
  my @fhosts;
  my @rhosts;
  foreach $host (split(/[\s+,]+/, $self->{servers})) {
    my $cmd = "unset";
    my ($dom, $srv) = split(/:/, $host);
    if ($self->{format} eq 'nslookup') {
      $cmd = $command . " " . $dom . " " . $srv . " >/dev/null";
    } else {
      $cmd = $command . " " . $dom . " \@" . $srv . " 2\>\&1 \>/dev/null";
    }
    $self->logging("testing: \'$cmd\'") if ($self->debug);
    system($cmd);
    $res = $? >> 8;
    if ($res) { # we had a problem
      $self->logging("Failed: $cmd");
      push @fhosts, "$host:$res";
    } else {
      $self->logging("Succeeded: $cmd") if ($self->debug>2);
    }
  }
  if ($#fhosts>=0) {
    $self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
    $self->ErrorString('DNS '.(join(', ', @fhosts)).'.');
    return;
  } else {
    $self->logging("returning normally") if ($self->debug);
    return 1;   # test passed
  }
}
  
1; # this must be here
