package SNAP::Tests::Freshclam;

use SNAP::Tests::GrepFor;
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Tests::GrepFor);	
$VERSION='1.1';

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  
  # initialize some internal counters
  $self->{_count}=0;
  $self->{_seek}=0;
  $self->{_logsize}=0;
  $self->{_logfilesave}=0;
  
  if (! defined $self->{grepfor}) {
      $self->{grepfor} = 'Your ClamAV installation is OUTDATED';
  }
  
  if (! defined $self->{logfile}) {
      $self->{logfile} = '/var/log/freshclam';
  }
  
  return $self;
}

1;

