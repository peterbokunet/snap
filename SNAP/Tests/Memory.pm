package SNAP::Tests::Memory;

use SNAP::Test;
use vars qw(@ISA $VERSION);
our @ISA = qw(SNAP::Test);
my $VERSION='1.0';

use strict;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  $self->{threshold} ||= 10240; # default 10 GB in MB
  $self->logging("Memory monitor: threshold=$self->{threshold}MB");
  return $self;
}

my $ltime;

sub test {
  my $self = shift;

  $self->logging('->test()')
      if ($self->{_DEBUG});

  my $lnow = time % 3600;
  my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
  $ltime = $lnow;

  if (! open(MEMINFO, '/proc/meminfo')) {
      $self->logging("ERROR: cannot open /proc/meminfo");
      $self->ErrorString('!M Cannot read /proc/meminfo');
      return;
  }

  my %mem;
  while (<MEMINFO>) {
      if (/^(\w+):\s+(\d+)/) {
          $mem{$1} = $2; # values in kB
      }
  }
  close(MEMINFO);

  my $avail_mb = int(($mem{MemAvailable} || 0) / 1024);
  my $total_mb = int(($mem{MemTotal} || 0) / 1024);
  my $used_mb = $total_mb - $avail_mb;

  $self->logging("Memory: ${avail_mb}MB available, ${total_mb}MB total, threshold=$self->{threshold}MB")
      if ($self->{_DEBUG});

  if ($avail_mb < $self->{threshold}) {
      $self->logging("LOW MEMORY: ${avail_mb}MB available (threshold: $self->{threshold}MB)");
      $self->ErrorString("!M LOW MEM: ${avail_mb}MB avail of ${total_mb}MB (threshold: $self->{threshold}MB)");
      return;
  }

  $self->logging("returning normally") if ($self->{_DEBUG});
  return 1; # test passed
}

1; # this must be here
