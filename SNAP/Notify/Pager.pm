package SNAP::Notify::Pager;

use strict;
use SNAP::Notify::Base;
use vars qw(@ISA);
our @ISA = qw(SNAP::Notify::Base);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  my $cfg = $_[0];
  if (ref($cfg)) {
    $self->{pager} = $cfg->value('Pager', 'pager') || $cfg->mainvalue('pager');
    $self->{page} = $cfg->value('Pager', 'page') || $cfg->mainvalue('page');
  }
  bless $self, $class;

  if ($self->{pager} && -x $self->{pager} && defined $self->{page} && defined $self->hostname) {
    $self->{_available} = 1;
    $self->logging("Pager notification loaded");
  } else {
    $self->{_available} = 0;
  }
  return $self;
}

sub send {
  my $self = shift;
  my $msg = shift;
  return 0 unless $self->{_available};

  my $syscall = $self->{pager} . ' -f ' . $self->hostname . ' -p ' . $self->{page} . " \"$msg\"";
  system($syscall);
  if ($? >> 8) {
    $self->logging("Error in system call for: \"$syscall\"");
    return 0;
  }
  $self->logging("Pager: sent '$msg'") if ($self->debug > 2);
  return 1;
}

1;
