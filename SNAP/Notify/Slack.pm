package SNAP::Notify::Slack;

use strict;
use SNAP::Notify::Base;
use vars qw(@ISA);
our @ISA = qw(SNAP::Notify::Base);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  my $cfg = $_[0];
  $self->{slack} = $cfg->value('Slack', 'url') if ref($cfg);
  # fall back to main config for backward compat
  $self->{slack} ||= $cfg->mainvalue('slack') if ref($cfg);
  bless $self, $class;

  eval "use LWP::UserAgent;";
  if ($@ =~ /\w/) {
    $self->logging("WARNING: Could not load LWP::UserAgent for Slack");
    $self->{_available} = 0;
  } else {
    $self->{_available} = 1;
    $self->logging("Slack notification loaded");
  }
  return $self;
}

sub send {
  my $self = shift;
  my $msg = shift;
  return 0 unless $self->{_available};
  return 0 unless (defined $self->{slack} && $self->{slack} ne '');

  my $update = $self->hostname . ': ' . ($msg || $self->subject);
  my $json = '{"text":"' . $update . '"}';
  my $req = HTTP::Request->new('POST', $self->{slack});
  $req->header('Content-Type' => 'application/json');
  $req->content($json);

  my $lwp = LWP::UserAgent->new;
  my $response = $lwp->request($req);

  $self->logging("Slack: sent '$update'") if ($self->debug > 2);
  return 1;
}

1;
