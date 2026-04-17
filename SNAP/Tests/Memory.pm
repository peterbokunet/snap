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

  my ($avail_mb, $total_mb) = ($^O eq 'darwin') ? _mem_darwin() : _mem_linux();

  if (!defined $avail_mb) {
      $self->ErrorString('!M Cannot read memory info');
      return;
  }

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

sub _mem_linux {
  if (! open(MEMINFO, '/proc/meminfo')) {
      return (undef, undef);
  }
  my %mem;
  while (<MEMINFO>) {
      if (/^(\w+):\s+(\d+)/) {
          $mem{$1} = $2;
      }
  }
  close(MEMINFO);
  my $avail_mb = int(($mem{MemAvailable} || 0) / 1024);
  my $total_mb = int(($mem{MemTotal} || 0) / 1024);
  return ($avail_mb, $total_mb);
}

sub _mem_darwin {
  my $total_bytes = `sysctl -n hw.memsize 2>/dev/null`;
  chomp $total_bytes;
  return (undef, undef) unless $total_bytes;

  my $total_mb = int($total_bytes / 1048576);

  my $page_size = `sysctl -n hw.pagesize 2>/dev/null`;
  chomp $page_size;
  $page_size ||= 4096;

  my $free_pages = 0;
  my $inactive_pages = 0;
  my $speculative_pages = 0;
  foreach (`vm_stat 2>/dev/null`) {
      $free_pages = $1 if /Pages free:\s+(\d+)/;
      $inactive_pages = $1 if /Pages inactive:\s+(\d+)/;
      $speculative_pages = $1 if /Pages speculative:\s+(\d+)/;
  }
  my $avail_mb = int(($free_pages + $inactive_pages + $speculative_pages) * $page_size / 1048576);
  return ($avail_mb, $total_mb);
}

1; # this must be here
