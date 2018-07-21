package SNAP::Tests::Ping;

use SNAP::Test;
use vars qw(@ISA $VERSION);
our @ISA = qw(SNAP::Test);	
my $VERSION='1.2';

use strict;

# put any modules you want to use here:
use Net::Ping;

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  $self->logging("ICMP pinging hosts: $self->{hosts}");
  return $self;
}

my %vhosts;
my $ltime;
  
sub test {
  my $self = shift;
  my @fhosts;
  my $host;
  my $state;


  $self->logging('->test()')
      if ($self->{_DEBUG});

  my $lnow = time % 3600;
  my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
  $ltime = $lnow;

  my $p=Net::Ping->new('icmp', $self->{timeout});
  foreach $host (split(/[\s+,]+/, $self->{hosts})) {
    if (! defined $vhosts{$host}) {
      $self->logging("Presuming $host is UP")
	if ($self->debug);
      $vhosts{$host} = 'UP';
    }

    $self->logging("testing: $host")
	if ($self->debug);

    if (! $p->ping($host)) {
      $self->logging("Failed to ping $host")
	if ($self->{_DEBUG});
      $state = 'DWN';
    } else {
      $self->logging("Succeeded pinging $host")
	  if ($self->debug);
      $state = 'UP';
    }

    # if we were up, now alert that we're down.  we'll also alert
    # if the $nag flag is set and the state is anything but UP

    $self->logging("about to report: host=$host vhosts=$vhosts{$host} state=$state nag=$nag")
      if ($self->debug);

    if (($vhosts{$host} ne $state) || (($nag eq 'YES') && ($state ne 'UP'))) {
      push @fhosts, "$host:$state";
      $self->logging("adding: $host:$state")
	if ($self->debug);
    }
    $vhosts{$host} = $state;
  }

  if ($#fhosts>=0) {
    $self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
    $self->ErrorString('!H '.(join(', ', @fhosts)).'.');
    return;
  } else {
    $self->logging("returning normally") if ($self->{_DEBUG});
    return 1;   # test passed
  }
}
  
1; # this must be here
