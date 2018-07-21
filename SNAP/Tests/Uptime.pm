package SNAP::Tests::Uptime;

use SNAP::Test;
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
my $VERSION='1.0';

use strict;

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  $self->{os} = `$self->{uname} -s`;
  $self->logging("Set OS to: $self->{os}");
  return $self;
}
  
sub test {
  my $self = shift;
  $self->logging("starting test") if ($self->debug);
  my $one = undef;
  my $five = undef;
  my $fteen = undef;
  my $err = '';
  if (! defined $self->{_uptime}) {
    my $uptime = '/usr/bin/uptime';
    $uptime = '/bin/uptime'          if ($self->{os} =~ /Solaris/);
    $uptime = '/bin/uptime'          if ($self->{os} =~ /SunOS/);
    $uptime = '/usr/bin/uptime'      if ($self->{os} =~ /AIX/);
    $uptime = '/usr/bin/uptime'      if ($self->{os} =~ /Linux/);
    $uptime = '/usr/bin/uptime'      if ($self->{os} =~ /Darwin/);
    $uptime = '/usr/bin/uptime'      if ($self->{os} =~ /FreeBSD/);
    $uptime = '/usr/bin/uptime'      if ($self->{os} =~ /OpenBSD/);
    $uptime = '/usr/bin/uptime'      if ($self->{os} =~ /NetBSD/);
    if (-x $uptime) {
      $self->{_uptime} = $uptime;
      $self->logging("Set 'uptime' command to \"$uptime\"");
    } else {
      $self->{_uptime} = 'noop';
      $self->logging("Disabled.  No command at \"$uptime\"");
      return;
    }
  } elsif ($self->{_uptime} eq 'noop') {
    return;
  }
    
  if (($self->{os} =~ /AIX/) ||
      ($self->{os} =~ /Solaris/) ||
      ($self->{os} =~ /SunOS/) ||
      ($self->{os} =~ /Linux/) ||
      ($self->{os} =~ /Darwin/) ||
      ($self->{os} =~ /FreeBSD/) ||
      ($self->{os} =~ /OpenBSD/) ||
      ($self->{os} =~ /NetBSD/)) {
      #  12:11AM   up 322 days, 10 hrs,  1 user,  load average: 0.00, 0.00, 0.00
      
      ($one, $five, $fteen) = (`$self->{_uptime}` =~ /(\d+\.\d+)/g);

      $self->logging(sprintf("found: %s : %s : %s", $one, $five, $fteen))
	  if ($self->debug);

  } else {
      $self->logging(sprintf("get your OS (%s) certified...", $self->{os}));
      return;
  }

  if (defined $self->{thresh1}) {
      $self->logging(sprintf("comparing thresh1: %s with  %s", $self->{thresh1}, $one))
	  if ($self->debug);
      if ( $one gt $self->{thresh1}) {
	  $self->logging(sprintf("thresh1: %s gt %s", $five, $self->{thresh1}))
	      if ($self->debug);
	  if ($err ne '') { $err .= '; '; }
	  $err .= sprintf("1m cpu \@ %s", $one);
      }
  }

  if (defined $self->{thresh5}) {
      $self->logging(sprintf("comparing thresh5: %s with  %s", $self->{thresh5}, $five))
	  if ($self->debug);
      if ($five gt $self->{thresh5}) {
	  $self->logging(sprintf("thresh5: %s gt %s", $five, $self->{thresh5}))
	      if ($self->debug);
	  if ($err ne '') { $err .= '; '; }
	  $err .= sprintf("5m cpu \@ %s", $five);
      }
  }
  
  if (defined $self->{thresh15}) {
      $self->logging(sprintf("comparing thresh15: %s with  %s", $self->{thresh15}, $fteen))
	  if ($self->debug);
      if ($fteen gt $self->{thresh15}) {
	  $self->logging(sprintf("thresh15: %s gt %s", $fteen, $self->{thresh15}))
	      if ($self->debug);
	  if ($err ne '') { $err .= '; '; }
	  $err .= sprintf("15m cpu \@ %s", $fteen);
      }
  }

  if ($?>>8) {
    $err = "Could not exec ".$self->{_uptime}.", exit w/non-zero status";
  }
  if ($err=~/\w/) {
    $self->ErrorString($err);
    $self->logging("Returning with ErrorSting") if ($self->debug);
    return;
  } else {
    $self->logging("Returning normal") if ($self->debug);
    return 1;
  }
}

1;

