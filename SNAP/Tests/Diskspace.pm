package SNAP::Tests::Diskspace;

use SNAP::Test;
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
my $VERSION='1.2';

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
  my $skip = 0;
  my $res = '';
  my ($dev, $total, $free, $mnt);
  my $ignored;
  my $err = '';
  if (! defined $self->{_dfcmd}) {
    my $dfcmd = '/usr/bin/df -k';
    $dfcmd = '/usr/sbin/df -k' if ($self->{os} =~ /Solaris/);
    $dfcmd = '/usr/sbin/df -k' if ($self->{os} =~ /SunOS/);
    $dfcmd = '/usr/bin/df -k'  if ($self->{os} =~ /AIX/);
    $dfcmd = '/bin/df -k'      if ($self->{os} =~ /Linux/);
    $dfcmd = '/bin/df -k'      if ($self->{os} =~ /Darwin/);
    $dfcmd = '/bin/df -k'      if ($self->{os} =~ /FreeBSD/);
    $dfcmd = '/bin/df -k'      if ($self->{os} =~ /OpenBSD/);
    $dfcmd = '/bin/df -k'      if ($self->{os} =~ /NetBSD/);
    $self->{_dfcmd} = $dfcmd."|";
    $self->logging("Set 'df' command to \"$dfcmd\"");
  }

  if (! exists $self->{_ignore}) {
    @{$self->{_ignore}} = split(/[,\s]+/, $self->{ignore});
  }
  if (! open (DF, $self->{_dfcmd})) {
    $self->ErrorString("Error running df for disk space");
    $self->logging("could not exec dfcmd \"".$self->{_dfcmd}."\"");
    return;
  }
  <DF>; # dump the header
  while (<DF>) {
    chop;
    $res .= $_;

    my $count = $res =~ s/((^|\s)\S)/$1/g;

    # if this is a multi-line result, we need to detect if we're
    # in the first line.  If so, cache it and prepend it to the
    # next line.

    next
      if ($count < 2);

    $_ = $res;
    $res = '';

    $self->logging('Evaluating: ' . $_)
	if ($self->debug);

    if ($self->{os} =~ /AIX/) {
      ($dev, $total, $free, $mnt) = (split)[0,1,2,6];
    } else {
      ($dev, $total, $free, $mnt) = (split)[0,1,3,5];
    }
    $skip = 0;
    foreach $ignored (@{$self->{_ignore}}) {
      if (($ignored eq $dev) or ($ignored eq $mnt)) {
        $self->logging("ingoring $mnt($dev) because we're ignoring \"$ignored\"")
	    if ($self->debug);
        $skip = 1;
	last;
      }
    }
    next if ($skip);
    my $limit;
    if (defined $self->{$mnt}) {
      if ($self->{$mnt}=~/\%$/) {
	chop($self->{$mnt});
        my $coolstring = "(".$self->{$mnt}."%% of $total)";
	$self->{$mnt} = int($total*(0.01*$self->{$mnt}));
        $self->logging("$mnt threshold now set to ".$self->{$mnt}." blocks ".$coolstring);
      }
      $limit = $self->{$mnt};
      $self->logging("Using specific space of $limit for $mnt")
	  if ($self->debug > 1);
    } elsif (defined $self->{defaultspace}) {
      $limit = $self->{defaultspace};
      $self->logging("Using default of $limit for $mnt")
	  if ($self->debug > 1);
    } else {
      $self->ErrorString("no \'defaultspace\' defined for Diskspace test");
      $self->logging("No \"defaultspace\" defined for test. Leaving test.");
      return;
    }
    if ($free < $limit) {
      $self->logging("$mnt low at ".$free."k");
      if ($err=~/\w/) {
        $err.=", $mnt low at ".$free."k";
      } else {
	$err = "$mnt low at ".$free."k";
      }
    }
  }
  close DF;
  if ($?>>8) {
    $err = "Could not exec ".$self->{_dfcmd}.", exit w/non-zero status";
  }
  if ($err=~/w/) {
    $self->ErrorString($err);
    $self->logging("Returning with ErrorSting")
	if ($self->debug);
    return;
  } else {
    $self->logging("Returning normal")
	if ($self->debug);
    return 1;
  }
}
  
1; # this must be here
