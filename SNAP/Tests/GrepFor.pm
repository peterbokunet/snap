package SNAP::Tests::GrepFor;   # modify for your package name.
			      # must match SNAP/Tests/file.pm
			      # and [File] in config file must
			      # match, case sensitive.

# Example:
#[TcpNoRimPorts]
#grepfor = No TCP ports available
#logfile = /usr/syslog/syslog

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
    
    # initialize some internal counters
    $self->{_count}=0;
    $self->{_seek}=0;
    $self->{_logsize}=-1;
    $self->{_logfilesave}=0;

    return $self;
}

sub test {
    my $self = shift;
    $self->logging("->test()") 
	if ($self->debug > 3);
    
    # stat()[7] is size; handle log rolling gracefully
    my $cursize = (stat($self->{logfile}))[7];

    if (($cursize < $self->{_logsize}) || 
	(! defined $self->{_logfilesave})) {
	
	# meaning file was rolled, or we're running for the first time.
	
	$self->logging("log rolled: \'".$self->{grepfor}."\'") 
	    if ($self->debug);
	
	# reset where we were in the file and the incident counter
	$self->{_count}=0;
	$self->{_seek}=0;
    }

    $self->{_logsize} = $cursize;

    # Now open the file, perhaps we should specify read-only?
    if (! open (LOGF, $self->{logfile})) {
	$self->ErrorString("Could not open ".$self->{logfile}." for test");
	$self->logging("Could not open ".$self->{logfile}." for test");
	return;
    }
    
    # Log file is open, now jump to where we last left off
    
    $self->logging("seeking to ".$self->{_seek}) 
	if ($self->debug);
    seek(LOGF, $self->{_seek}, 0);
    
    # now iterate through the log to the end
    
    my $curpos;
    my $count = 0;
    for ($curpos= tell(LOGF); defined($_=<LOGF>); $curpos = tell(LOGF)) {
	
	# if the line in $_ contains the string, increment the counter
	
	$count++ if ($_=~$self->{grepfor});
    }
    close(LOGF);
    
    # close the log file and remember where we are for next time.
    
    $self->{_seek}=$curpos;
    $self->logging("Found $count errors.") 
	if ($self->debug);
    $self->logging("new position is ".$self->{_seek}) 
	if ($self->debug);
    
    if (! defined $self->{_logfilesave}) {
	# don't page upon startup, man.
	$self->{_count} = $count;
	$self->{_logfilesave} = $self->{logfile};
    } elsif ($count) {
	my $pkg = (split(/::/, ref($self)))[$#_];
	$self->ErrorString($pkg.'('.($self->{_count}+$count).",".$count.")");
	$self->{_count}+=$count;
	$self->logging("returning with error") if ($self->debug);
	return;
    }
    $self->logging("return normally") if ($self->debug);
    return 1;
}

1;

