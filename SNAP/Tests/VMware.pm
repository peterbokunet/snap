package SNAP::Tests::VMware;

use SNAP::Tests::220Banner;
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Tests::220Banner);
$VERSION='1.1';

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;

  $self->{port} = 902
    if (! $self->{port});

  $self->logging("Expecting 220 Banner on $self->{port} from: $self->{dest}");
  return $self;
}

1;

