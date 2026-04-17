package SNAP::Notify::Mail;

use strict;
use SNAP::Notify::Base;
use vars qw(@ISA);
our @ISA = qw(SNAP::Notify::Base);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  my $cfg = $_[0];
  if (ref($cfg)) {
    $self->{mail} = $cfg->value('Mail', 'to') || $cfg->mainvalue('mail');
    $self->{mailer} = $cfg->value('Mail', 'mailer') || $cfg->mainvalue('mailer');
  }
  bless $self, $class;

  my $basemail = (split(/\s+/, $self->{mailer} || ''))[0];
  if ($basemail && -x $basemail && defined $self->{mail}) {
    $self->{_available} = 1;
    $self->logging("Mail notification loaded");
  } else {
    $self->{_available} = 0;
  }
  return $self;
}

sub send {
  my $self = shift;
  my $msg = shift;
  return 0 unless $self->{_available};

  if (!open(MAILER, "|" . $self->{mailer})) {
    $self->logging("ERROR: could not execute " . $self->{mailer});
    return 0;
  }
  print MAILER "To: " . $self->{mail} . "\n";
  print MAILER "From: " . $self->from . "\n";
  print MAILER "Subject: " . $self->subject . "\n\n";
  print MAILER "\n" . $msg . "\n";
  print MAILER $self->signature . "\n" if (defined $self->signature);
  close(MAILER);
  return 0 if ($? >> 8);

  $self->logging("Mail: sent to " . $self->{mail}) if ($self->debug > 2);
  return 1;
}

1;
