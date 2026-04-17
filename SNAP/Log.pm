package SNAP::Log;

use strict;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Carp;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $cfg = shift;
  my $self = {
    _OKAYTOLOG => 0,
    _DEBUG     => 0,
    _LOGFILE   => undef,
    _STDOUT    => 0,
  };
  bless $self, $class;

  if (ref($cfg)) {
    $self->{_DEBUG}   = $cfg->mainvalue('debug') || 0;
    $self->{_LOGFILE} = $cfg->mainvalue('logfile');
    my $sysloglvl     = $cfg->mainvalue('sysloglvl');
    my $syslogid      = $cfg->mainvalue('syslogid');
    my $syssock       = $cfg->mainvalue('syssock');

    if (defined $sysloglvl && defined $syslogid) {
      my ($facility, $lvl) = split(/:/, $sysloglvl);
      if (defined $facility && defined $lvl) {
        $self->{_LOGFACILITY} = $facility;
        $self->{_LOGLEVEL}    = $lvl;
        setlogsock($syssock) if defined $syssock;
        openlog($syslogid, 'cons,pid', $facility);
        syslog($lvl, '%s starting', $syslogid);
        $self->{_OKAYTOLOG} = 1;
      }
    }
  }
  return $self;
}

sub enable_stdout {
  my $self = shift;
  $self->{_STDOUT} = 1;
}

sub log {
  my $self = shift;
  my $lvl  = shift;
  my $msg  = shift;
  if (!defined $msg) {
    $msg = $lvl;
    $lvl = $self->{_LOGLEVEL};
  }

  syslog($lvl, $msg) if $self->{_OKAYTOLOG};

  if ($self->{_STDOUT}) {
    my $ts = localtime;
    print "[$ts] $msg\n";
  }

  if (defined $self->{_LOGFILE} && $self->{_LOGFILE} ne '/dev/null') {
    if (open(my $fh, '>>', $self->{_LOGFILE})) {
      my $ts = localtime;
      print $fh "[$ts] $msg\n";
      close($fh);
    }
  }
}

# backward-compatible alias for $notify->logging() calls
sub logging { return shift->log(@_); }

sub debug {
  my $self = shift;
  $self->{_DEBUG} = shift if (@_);
  return $self->{_DEBUG};
}

1;
