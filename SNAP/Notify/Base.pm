package SNAP::Notify::Base;

use strict;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Carp;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  my $cfg = shift;

  if (ref($cfg)) {
    for my $key (qw(debug hostname signature subject from sysloglvl syslogid syssock)) {
      $self->{$key} = $cfg->mainvalue($key);
    }
  }
  $self->{_DEBUG} = $self->{debug} || 0;
  $self->{_OKAYTOLOG} = 0;
  bless $self, $class;

  if ((defined $self->{sysloglvl}) and (defined $self->{syslogid})) {
    $self->_startlog();
  }
  return $self;
}

sub send { return 0; }  # override in subclass

sub hostname {
  my $self = shift;
  $self->{hostname} = shift if (@_);
  return $self->{hostname};
}

sub subject {
  my $self = shift;
  $self->{subject} = shift if (@_);
  return $self->{subject};
}

sub from {
  my $self = shift;
  $self->{from} = shift if (@_);
  return $self->{from};
}

sub signature {
  my $self = shift;
  $self->{signature} = shift if (@_);
  return $self->{signature};
}

sub debug {
  my $self = shift;
  $self->{_DEBUG} = shift if (@_);
  return $self->{_DEBUG};
}

sub _startlog {
  my $self = shift;
  my ($facility, $lvl) = split(/:/, $self->{sysloglvl});
  return unless (defined $facility && defined $lvl);
  $self->{_LOGFACILITY} = $facility;
  $self->{_LOGLEVEL} = $lvl;
  if (defined $self->{syssock}) {
    setlogsock($self->{syssock});
  }
  openlog($self->{syslogid}, 'cons,pid', $facility);
  $self->{_OKAYTOLOG} = 1;
}

sub logging {
  my $self = shift;
  return unless $self->{_OKAYTOLOG};
  my $lvl = shift;
  my $msg = shift;
  if (!defined $msg) {
    $msg = $lvl;
    $lvl = $self->{_LOGLEVEL};
  }
  syslog($lvl, $msg);
}

1;
