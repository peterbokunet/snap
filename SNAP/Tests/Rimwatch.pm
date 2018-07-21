package SNAP::Tests::Rimwatch;   # modify for your package name.
			      # must match SNAP/Tests/file.pm
			      # and [File] in config file must
			      # match, case sensitive.

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.0';

# put any modules you want to use here:
use Net::Ping;

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
  my %old;
  my %new;
  my @reset;
  if (-e $self->{savefile}) {
    $self->logging("reading savefile") if ($self->debug);
    if (! open (SAVE, $self->{savefile})) {
      $self->logging("MAIL: could not read savefile: \"".$self->{savefile}."\"");
    } else {
      while (<SAVE>) {
        chop;
        my($first, $second) = split(/ = /, $_);
        $old{$first} = $second;
      }
      close(SAVE);
    } 
  }
  if (! open(P, $self->{devcmd}."|")) {
    $self->ErrorString("could not exec ".$self->{cmd});
    $self->logging("MAIL: could not run ".$self->{cmd}.", return with error");
    return;
  }
  my $who, $dev;
  while (<P>) {
    chop;
    ($dev) = substr($_, 0, 10);
    ($who) = substr($_, 51, 15);
    $who=~s/\s+//;
    $dev=~s/\s+//;
    next if ($who!~/(\d+)\.(\d+)\.(\d+)\.(\d+)/);
    if ($dev=~/^RIM/) { 
      if ($dev eq $old{$who}) {
        push @reset, $dev;
      } 
      $new{$who} = $dev;
    }
  }
  close(P);
  if ($?>>8) {
    $self->logging("MAIL: ".$self->{cmd}." exitted with non-zero status");
    $self->ErrorString("Rimwatch: exitted with non-zero status");
    return;
  }

  if (! open(SAVE, ">".$self->{savefile})) {
    $self->logging("MAIL: could not write to savefile: \"".$self->{savefile}."\"");
    $self->ErrorString("Rimwatch:Could not write to savefile");
    return;
  }
  foreach (keys %new) {
    print SAVE "$_ = $new{$_}\n";
  }
  close(SAVE);

  my $badhosts = 0;
  if ($#reset>=24) {
    foreach (@reset) {
      my $cmd = $self->{nstop}." $_";
      system($cmd);
      if ($?>>8) {
	$badhosts++;
	next
      }
      sleep 1;
      $cmd = $self->{nstart}." $_";
      system($cmd);
    }
    if ($badhhosts) {
      $self->ErrorString(($#reset-$badhosts)." RIM devices reset.");
      $self->logging("$#reset RIM devices reset");
    } else {
      $self->ErrorString("$#reset RIM devices reset");
      $self->logging("$#reset RIM devices reset");
    }
    return;
  } else {
    return 1;
  }
}

1; # this must be here
