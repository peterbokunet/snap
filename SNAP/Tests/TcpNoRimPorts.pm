package SNAP::Tests::TcpNoRimPorts;   # modify for your package name.
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
  my $mystat = 0;
  if (((stat($self->{logfile}))[7] < $self->{_logsize}) || (! defined $self->{_logfilesave})) {
    # meaning file was rolled, or we're running for the first time.
    $self->logging("first time: Grepping for \"".$self->{grepfor}."\"") if ($self->debug);
    $self->{_count}=0;
    $self->{_seek}=0;
  }
  $self->{_logsize} = (stat($self->{logfile}))[7];

  if (! open (LOGF, $self->{logfile})) {
    $self->ErrorString("Could not open ".$self->{logfile}." for test");
    $self->logging("Could not open ".$self->{logfile}." for test");
    return;
  }
  $self->logging("seeking to ".$self->{_seek}) if ($self->debug);
  seek(LOGF, $self->{_seek}, 0);
  my $curpos;
  my $count = 0;
  for ($curpos= tell(LOGF); defined($_=<LOGF>); $curpos = tell(LOGF)) {
    $count++ if ($_=~$self->{grepfor});
  }
  close(LOGF);
  $self->{_seek}=$curpos;
  $self->logging("Found $count errors.") if ($self->debug);
  $self->logging("new position is ".$self->{_seek}) if ($self->debug);

  if (! defined $self->{_logfilesave}) {
    # don't page upon startup, man.
    $self->{_count} = $count;
    $self->{_logfilesave} = $self->{logfile};
  } elsif ($count) {
    #$self->ErrorString($self->{errorstring}.": (".($self->{_count}+$count).",".$count.")");
    $self->ErrorString("No RIM ports: (".($self->{_count}+$count).",".$count.") Check Netx Devices!");
    $self->{_count}+=$count;
    $self->logging("returning with error") if ($self->debug);
    return;
  }
  $self->logging("return normally") if ($self->debug);
  return 1;
}

1; # this must be here
