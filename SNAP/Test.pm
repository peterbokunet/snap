=head1 NAME

SNAP::Test - Abstract class for tests

=head1 DESCRIPTION

This is an abstract class that provides the framwork for tests.  Creating
an instance of this does no useful testing.  Tests should be a subclass of
this.  The subclasses can then use the framework provided in their
implementation.  At a minimum test() should be over-ridden.

=head1 Provides

=over 2

=item  new()

Reads the configuration and initializes values:

=over 4

  ErrorString = empty string
  Frequency   = 3600 seconds (or to what frequency is set in [main])
  _DEBUG      = 0 (or to what "debug" is set in [main])

=back

=item  ErrorString()

Accessor method for getting ErrorString or sets ErrorString to what's passed.

=item  clearErrorString()

Clears ErrorString.

=item  test()

Does nothing.  Override this in a sub-class to do work.

=item  test_page()

Invokes the paging mechanism to send C<this is a test!> as an alert.

=item  logging()

Use this as a way to pass events to the logging system.  Takes two
arguments: the first is the level of the message and the actual message.
The if the level is greater than or equal to C<debug()> the
message will be logged.

=item  debug()

Accessor method to get the value of debug or to set the value of 
debug.

=back

=head1 TODO

Implement a state management function.

=cut

package SNAP::Test;
# use vars qw(@ISA $VERSION);
# use Data::Dumper;
our $VERSION = '1.00';
my $Debugging = 0;

use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  my $cfg = shift;
  my $ntfy = shift;
  return if ((! defined $cfg) || (! defined $ntfy));
  my $section = (split(/::/, $proto))[$#_];
  my %artful = $cfg->getsection($section);
  foreach (keys %artful) {
    $self->{$_} = $artful{$_};
  }
  $self->{_notify} = $ntfy;
  $self->{ErrorString} = "";
  $self->{Frequency} = $cfg->mainvalue("frequency") ? 
      $cfg->mainvalue("frequency") : 3600; # how often to send a state reminder (secs)
  $self->{_DEBUG} ||= $cfg->mainvalue("debug");

  if ($self->{debug} > $self->{_DEBUG}) {
      $self->{_DEBUG} = $self->{debug};
  }


  bless($self, $class);

  $self->logging('->new()')
      if ($self->debug > 2);

  return $self;
}

sub ErrorString {
  my $self = shift;
  if (@_) { $self->{ErrorString} .= join(' ', @_) };
  return $self->{ErrorString};
}

sub clearErrorString {
  my $self = shift;
  $self->{ErrorString} = '';
  return $self->{ErrorString};
}

sub test {
  my $self = shift;
  $self->logging('->test()')
      if ($self->debug);
  return 0;
}

sub test_page {
  my $self = shift;
  if (! ref($self->{_notify})) {
    print " - - whoa baby, not a ref in self->{_notify}\n";
    return;
  }
  return $self->{_notify}->sendpage("this is a test!");
}

sub logging {
  my $self = shift;
  my $lvl = shift;
  my $msg = shift;
  my $pkg = (split(/::/, ref($self)))[$#_].": ";
  if (! defined $msg) {
    return $self->{_notify}->logging($pkg.$lvl);
  } else {
    return $self->{_notify}->logging($lvl, $pkg.$msg);
  }
}

sub debug {
  my $self = shift;
  my $class = ref($self);
  #confess "usage: $class->debug(level)" unless @_ == 1;
  my $level = shift;
  if (! defined $self->{_DEBUG}) {
      $self->{_DEBUG} = $Debugging;
  }
  if (defined $level) {
      $self->{_DEBUG} = $level;
  }
  return $self->{_DEBUG};
}

sub DESTROY {
  my $self = shift;
  $self->logging("Destroying $self " . $self->Database)
      if ($self->debug);
}

1;
