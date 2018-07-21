package SNAP::Tests::Netxmon;   # modify for your package name.
			      # must match SNAP/Tests/file.pm
			      # and [File] in config file must
			      # match, case sensitive.

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.0';

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
  if (! defined $self->{netxlookup}) {
    $self->ErrorString("No netxlookup defined");
    $self->logging("No netxlookup defined! return with error");
    return;
  }
  my ($device, $type, $value);
  my %newlist;
  my %replist;
  $self->{_netxlookup} = $self->{netxlookup}."|" if (! defined $self->{_netxlookup});
  if (! open(NETX, $self->{_netxlookup})) {
    $self->ErrorString("Error running netxlookup");
    $self->logging("could not exec netxlookup: ".$self->{netxlookup}." return with error");
    return;
  }
  while (<NETX>) {
    chop;
    ($device, $type, $value) = split;
    $newlist{$device." ".$type} = $value;
  }
  close(NETX);
  if ($?>>8) {
    $self->ErrorString("netx_lookup exitted with non-zero status");
    $self->logging("MAIL: netx_lookup exitted with non-zero status");
    return;
  }
  foreach (sort (keys(%newlist))) {
    if ((defined $self->{_val}{$_}) && ($newlist{$_} ne $self->{_val}{$_})) {
      if (($_=~/TO$|GF$|HD$|POP$/) && (($newlist{$_}-$self->{_val}{$_}) == 1)) {
	$self->logging("$_ only went up one, skipping for now") if ($self->debug);
	next;
      }
      $self->logging("$_ changed from ".$self->{_val}{$_}." to ".$newlist{$_}) if ($self->debug);
      ($device, $type) = split;
      if (($type ne "PVC") && ($newlist{$_}!=0)) {
        $replist{$device}.=" " if (defined $replist{$device});
        $replist{$device}.=$type."(".$newlist{$_}.",".($newlist{$_}-$self->{_val}{$_}).")";
      } elsif ($type eq "PVC") {
        $replist{$device}.=" " if (defined $replist{$device});
        $replist{$device}.=(($self->{_val}{$_}>$newlist{$_})?"-":"+").abs($self->{_val}{$_} - $newlist{$_});
      }
    }
    $self->{_val}{$_} = $newlist{$_};
  }
  my $repstr = '';
  foreach (keys %replist) {  # will only cycle if replist contains something.
    $repstr.="; " if (length($repstr));
    $repstr.=$_." ".$replist{$_};
  }
  if (length($repstr)) {
    $self->logging("returning with error") if ($self->debug);
    $self->ErrorString($repstr);
    return; 
  } else {
    $self->logging("returning just fine") if ($self->debug);
    return 1;
  }
}

  
1; # this must be here
