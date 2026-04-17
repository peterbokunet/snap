package SNAP::Notify::Teams;

use strict;
use SNAP::Notify::Base;
use vars qw(@ISA);
our @ISA = qw(SNAP::Notify::Base);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  my $cfg = $_[0];
  $self->{teams} = $cfg->value('Teams', 'url') if ref($cfg);
  $self->{teams} ||= $cfg->mainvalue('teams') if ref($cfg);
  bless $self, $class;

  eval "use LWP::UserAgent;";
  if ($@ =~ /\w/) {
    $self->logging("WARNING: Could not load LWP::UserAgent for Teams");
    $self->{_available} = 0;
  } else {
    $self->{_available} = 1;
    $self->logging("Teams notification loaded");
  }
  return $self;
}

sub send {
  my $self = shift;
  my $msg = shift;
  return 0 unless $self->{_available};
  return 0 unless (defined $self->{teams} && $self->{teams} ne '');

  my $update = $self->hostname . ': ' . ($msg || $self->subject);
  my $json = '{"text":"' . $update . '"}';
  my $req = HTTP::Request->new('POST', $self->{teams});
  $req->header('Content-Type' => 'application/json');
  $req->content($json);

  my $lwp = LWP::UserAgent->new;
  my $response = $lwp->request($req);

  $self->logging("Teams: sent '$update'") if ($self->debug > 2);
  return 1;
}

1;
