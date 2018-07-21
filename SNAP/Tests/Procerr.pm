package SNAP::Tests::Procerr;   # modify for your package name.
			      # must match SNAP/Tests/file.pm
			      # and [File] in config file must
			      # match, case sensitive.

use SNAP::Test;	      # parent app.
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.1';

# put any modules you want to use here:

#Don't mess with this unless you know what you're doing.
sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  return $self;
}
  
sub test {
  my $self = shift;
  $self->logging("starting test") if ($self->debug);
  if (! opendir(TLOG, $self->{tlogdir})) {
    # $self->ErrorString("Could not open tlogdir for procerr check");
    $self->logging("Could not open ".$self->{tlogdir}."for procerr check");
    $self->logging("returning with error");
    return;
  }
  my $mystat = 0;
  my $tlogfile;
  foreach (readdir(TLOG)) {
    next if (/gz$/);
    my $statr = (stat($self->{tlogdir}."/".$_))[9];
    if ((/^Z/) && ($mystat < $statr)) {
      $mystat=$statr;
      $tlogfile=$self->{tlogdir}."/".$_;
    }
  }
  closedir(TLOG);
  if (! length($tlogfile)) {
    # There's nothing to look at, so why bother?
    $self->logging("Didn't find a tlogfile to look at! (netx not running)");
    return(1);
  }

  if ($self->{_tlogfile} ne $tlogfile) {
    $self->{_tlogfile}=$tlogfile;
    $self->{_count}=0;
    $self->{_seek}=0;
    $self->logging("looking at: ".$self->{_tlogfile}) if ($self->debug);
  } else {
    $self->logging("still looking at: ".$self->{_tlogfile}) if ($self->debug);
  }

  if (! open (TLOGF, $self->{_tlogfile})) {
    $self->ErrorString("Could not open tlog for procerr check");
    $self->logging("Could not open ".$tlogfile."for procerr check");
    return;
  }

  $self->logging("seeking to ".$self->{_seek}) if ($self->debug);
  seek(TLOGF, $self->{_seek}, 0);
  my $curpos;
  my $count = 0;
  for ($curpos= tell(TLOGF); defined($_=<TLOGF>); $curpos = tell(TLOGF)) {
    $count++ if ($_=~$self->{grepfor});
  }
  close(TLOGF);
  $self->{_seek}=$curpos;
  $self->logging("Found $count errors.") if ($self->debug);
  $self->logging("new position is ".$self->{_seek}) if ($self->debug);

  if (! defined $self->{_tlogfilesave}) {
    # don't page upon startup, man.
    $self->{_count} = $count;
    $self->{_tlogfilesave} = $tlogfile;
  } elsif ($count) {
    $self->ErrorString("ProcErrs: (".($self->{_count}+$count).",".$count.")");
    $self->{_count}+=$count;
    $self->logging("returning with error") if ($self->debug);
    return;
  }
  $self->logging("return normally") if ($self->debug);
  return 1;
}
  
1; # this must be here
