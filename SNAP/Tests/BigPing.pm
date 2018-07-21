package SNAP::Tests::BigPing;

use SNAP::Test;
use vars qw(@ISA $VERSION);
our @ISA = qw(SNAP::Test);	
my $VERSION='1.0';

use strict;

# put any modules you want to use here:
use Net::Ping;

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;

  if ($self->{bytes} > 1038) {
      $self->{bytes} = 1038;
  } else {
      if ($self->{bytes} < 64) {
	  $self->{bytes} = 64;
      }
  }
  $self->logging("Pinging " . $self->{bytes} . " bytes") if ($self->debug);
  return $self;
}
  
sub test {
  my $self = shift;
  $self->logging("starting test") if ($self->debug);
  my $host;
  my @fhosts;
  my @rhosts;
  my $p=Net::Ping->new('icmp', $self->{timeout}, $self->{bytes});
  $p->bind($self->{laddr}) if (defined $self->{laddr});
  foreach my $host (split(/[\s+,]+/, $self->{hosts})) {
    if (! $p->ping($host)) {
      $self->logging("Failed to ping $host") if ($self->debug);
      push @rhosts, $host;
    } else {
      $self->logging("Succeeded pinging $host") if ($self->debug);
    }
  }
  foreach $host (@rhosts) {
    if (! $p->ping($host)) {
      $self->logging("2nd Time: Failed to ping $host") if ($self->debug);
      push @fhosts, $host;
    } else {
      $self->logging("2nd Time: Succeeded pinging $host") if ($self->debug);
    }
  }
  if ($#fhosts>=0) {
    $self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
    $self->ErrorString('!H '.(join(', ', @fhosts)).'.');
    return;
  } else {
    $self->logging("returning normally") if ($self->debug);
    return 1;   # test passed
  }
}
  
1;
