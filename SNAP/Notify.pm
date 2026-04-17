=head1 NAME

SNAP::Notify - Handles notifications

=head1 DESCRIPTION

This should be an abstract class that subclasses can use for
outbound notifications.

=head1 Provides

=over 2

=item  new()

Initializes the notification methods.

=over 4

=item checkMail()
=item checkPager()

=back

=back

=head1 TODO

This needs to be rewritten to allow the notification configuration
to be derived from the conf file.  At this point everything is mostly
hard coded and it doesn't lend itself for any flexibility.

The controller needs to create an array of Notify objects and simply
call the same method on each.

=cut

package SNAP::Notify;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Carp;
my $Debugging = 0;

my $haveTeams = 'yes';
my $haveSlack = 'yes';
my $haveMail = 'no';
my $havePager = 'no';

use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self;
  my @depts = qw(debug teams teamsskiphost slack slackskiphost mail logfile mailer page pager sysloglvl from subject hostname signature syslogid syssock);

  if (ref($_[0])) {
    foreach (@depts) {
      $self->{$_}=$_[0]->mainvalue($_);
      if ($_ eq 'debug') {
	  $Debugging = ($_[0]->mainvalue($_) > $Debugging ? $_[0]->mainvalue($_) : $Debugging);
      }
    }
  } else { 
    my %arg = @_;
    foreach (@depts) {
      $self->{$_}=$arg{$_}
    }
  }
  bless $self, $class;
  if ((defined $self->{sysloglvl}) and (defined $self->{syslogid})) {
    $self->startlog();
  }
  if ($self->debug>2) {
      $self->logging(ref($self) . '->new');
      if (ref($_[0])) {
	  foreach (@depts) {
	      $self->logging('Notify::new() ' . $_ . ' => ' . $self->{$_});
	  }
      } else { 
	  my %arg = @_;
	  foreach (@depts) {
	      $self->logging('Notify::new() ' . $_ . ' => ' . $self->{$_});
	  }
      }
  }

  $self->logging("Errors logged between here and \"Using Notifications:\"\n".
		 "are only warnings.  The failure to load modules here will\n".
		 "not be fatal.");

  $self->checkTeams();
  $self->checkSlack();
  $self->checkMail();
  $self->checkPager();

  my $msg = '';
  $msg .= 'Teams '
      if ($haveTeams eq 'yes');
  $msg .= 'Slack '
      if ($haveSlack eq 'yes');
  $msg .= 'Mail '
      if ($haveMail eq 'yes');
  $msg .= 'Pager '
      if ($havePager eq 'yes');

  if ($msg eq '') {
      $self->logging('Using Notifications:   ****** NO Notifications Found ******');
  } else {
      $self->logging('Using Notifications: ' . $msg);
  }

  return $self;
}

sub checkPager {
  my $self = shift;
  my $pagerApp = $self->pager;
  my @nice_check;

  return 0
      if ($pagerApp eq '');

  if (! -x $pagerApp) {
    $self->logging('  ERROR: do not have permission to exec: '.$pagerApp);
    return;
  }

  push(@nice_check, 'pager')
    if (! defined $self->pager);
  push(@nice_check, 'page')
    if (! defined $self->page);
  push(@nice_check, 'hostname')
    if (! defined $self->hostname);
  if ($#nice_check>=0) {
    $self->logging('need '.(join(', ', @nice_check)).' defined to send a page');
    return;
  }

  $havePager = 'yes';
}


sub checkMail {
  my $self = shift;
  my $basemail = (split(/\s+/, $self->mailer))[0];

  return 0
      if ($basemail eq '');

  if (! -x $basemail) {
    $self->logging('  ERROR: do not have permission to exec: '.$basemail);
    return;
  }
  if (! defined $self->mail) {
    $self->logging('  ERROR: mail must be defined');
    return;
  }
  $haveMail = 'yes';
}






sub checkSlack {
    my $self = shift;
    my $mod = "use LWP::UserAgent;";
    my ($apikey) = $self->slack();

    return(0)
      if ((! defined $apikey) || ($apikey eq ''));

    $self->logging("Attempting to load \'$mod\'... ")
	if ($self->debug>2);
    eval $mod;
    if ($@=~/\w/) {  # eval caught something
	my $error = $@;  
	$self->logging("  WARNING: Could not load LWP::UserAgent module ($error)")
	    if ($self->debug);
	$self->logging('  Continuing without Slack');
	$haveSlack = 'no';
    } else {
	$self->logging('  Success loading Slack');
	$haveSlack = 'yes';
    }
}


sub checkTeams {
    my $self = shift;
    my $mod = "use LWP::UserAgent;";
    my ($apikey) = $self->teams();

    return(0)
      if ((! defined $apikey) || ($apikey eq ''));

    $self->logging("Attempting to load \'$mod\'... ")
	if ($self->debug>2);
    eval $mod;
    if ($@=~/\w/) {  # eval caught something
	my $error = $@;  
	$self->logging("  WARNING: Could not load LWP::UserAgent module ($error)")
	    if ($self->debug);
	$self->logging('  Continuing without Teams');
	$haveSlack = 'no';
    } else {
	$self->logging('  Success loading Teams');
	$haveSlack = 'yes';
    }
}




sub slack {
  my ($self) = shift;
  $self->{slack} = shift if (@_);
  $self->logging(ref($self).'->slack = '.$self->{slack})
      if ($self->debug>2);
  return $self->{slack};
}

sub teams {
  my ($self) = shift;
  $self->{teams} = shift if (@_);
  $self->logging(ref($self).'->teams = '.$self->{teams})
      if ($self->debug>2);
  return $self->{teams};
}

sub mail {
  my ($self) = shift;
  $self->{mail} = shift if (@_);
  $self->logging(ref($self).'->mail = '.$self->{mail})
      if ($self->debug>2);
  return $self->{mail};
}

sub logfile {
  my $self = shift;
  $self->{logfile} = shift if (@_);
  $self->logging(ref($self).'->logfile = '.$self->{logfile})
      if ($self->debug>2);
  return $self->{logfile};
}

sub mailer {
  my $self = shift;
  $self->{mailer} = shift if (@_);
  $self->logging(ref($self).'->mailer = '.$self->{mailer})
      if ($self->debug>2);
  return $self->{mailer};
}

sub page {
  my $self = shift;
  $self->{page} = shift if (@_);
  $self->logging(ref($self).'->page = '.$self->{page})
      if ($self->debug>2);
  return $self->{page};
}

sub pager {
  my $self = shift;
  $self->{pager} = shift if (@_);
  $self->logging(ref($self).'->pager = '.$self->{pager})
      if ($self->debug>2);
  return $self->{pager};
}

sub from {
  my $self = shift;
  $self->{from} = shift if (@_);
  $self->logging(ref($self).'->from = '.$self->{from})
      if ($self->debug>2);
  return $self->{from};
}

sub subject {
  my $self = shift;
  $self->{subject} = shift if (@_);
  $self->logging(ref($self).'->subject = '.$self->{subject})
      if ($self->debug>2);
  return $self->{subject};
}

sub hostname {
  my $self = shift;
  $self->{hostname} = shift if (@_);
  $self->logging(ref($self).'->hostname = '.$self->{hostname})
      if ($self->debug>2);
  return $self->{hostname};
}

sub signature {
  my $self = shift;
  $self->{signature} = shift if (@_);
  $self->logging(ref($self).'->signature = '.$self->{signature})
      if ($self->debug>2);
  return $self->{signature};
}

sub syssock {
  my $self = shift;
  $self->{syssock} = shift if (@_);
  $self->logging(ref($self).'->syssock = '.$self->{syssock})
      if ($self->debug>2);
  return $self->{syssock};
}

sub sysloglvl {
  my $self = shift;
  $self->{sysloglvl} = shift if (@_);
  carp(ref($self).'->sysloglvl = '.$self->{sysloglvl})
      if ($self->debug>2);
  return $self->{sysloglvl};
}

sub syslogid {
  my $self = shift;
  $self->{syslogid} = shift if (@_);
  carp(ref($self).'->syslogid = '.$self->{syslogid})
      if ($self->debug>2);
  return $self->{syslogid};
}




sub slackskiphost {
  my ($self) = shift;
  my $val = shift if (@_);
  if (defined $val && !($val =~ /^[nN0]/)) {
      $self->{slackskiphost} = 'yes';
  }
  $self->logging("Notify: slackskiphost: ".$self->{slackskiphost})
      if ($self->debug > 2);
  return $self->{slackskiphost};
}

sub teamsskiphost {
  my ($self) = shift;
  my $val = shift if (@_);
  if (defined $val && !($val =~ /^[nN0]/)) {
      $self->{teamsskiphost} = 'yes';
  }
  $self->logging("Notify: teamsskiphost: ".$self->{teamsskiphost})
      if ($self->debug > 2);
  return $self->{teamsskiphost};
}



sub sendmail {
  my $self = shift;
  my $msg = shift;
  my $subject = $self->subject || "undefined in $0";
  my $basemail = (split(/\s+/, $self->mailer))[0];

  return(0)
      if ($haveMail ne 'yes');

  if (! open(MAILER, "|".$self->mailer)) {
    $self->logging("ERROR: could not execute ".$self->mailer);
    return;
  } 
  print MAILER "To: ".$self->mail."\n";
  print MAILER "From: ".$self->from."\n";
  print MAILER "Subject: ".$self->subject."\n\n";
  print MAILER "\n".$msg."\n";
  print MAILER $self->signature."\n" if (defined $self->signature);
  close(MAILER);
  return if ($?>>8);	# error in exec call
  if ($self->debug>2) {
    my $debugstr.="Notify: sendmail: To:".$self->mail."; From: ".$self->from."; Subject: ".$self->subject." ";
    $debugstr.=$self->signature  if (defined $self->signature);
    $self->logging($debugstr);
  }
  return(1);
}


sub sendslack {
  my $self = shift;
  my $subject = $self->subject || "undefined in $0";
  my $update = $self->hostname.': '.$self->subject;
  my $result;
  my ($apikey) = $self->slack();

  return(0)
      if ($haveSlack ne 'yes');

#  $update = $self->subject
#      if ($self->slackskiphost ne '');

  $self->logging('Notify: sendslack('.$update.')')
      if ($self->debug>2);

  $self->logging('Notify: slack key: '.$apikey)
      if ($self->debug>2);

  $update .= ' '.`date`
      if ($self->debug>2);

# curl -X POST -H 'Content-type: application/json' --data '{"text":"Hello, World!"}' https://hooks.slack.com/services/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

  my $uri = $apikey;
  my $json = '{"text":"' . $update . '"}';
  my $req = HTTP::Request->new( 'POST', $uri );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json );

  my $lwp = LWP::UserAgent->new;
  my $response = $lwp->request( $req );
  my $content  = $response->decoded_content();

  if ( my $err = $@ ) {
      $self->logging('Notify: slack error')
  }
  
  return(1);
}


sub sendteams {
  my $self = shift;
  my $subject = $self->subject || "undefined in $0";
  my $update = $self->hostname.': '.$self->subject;
  my $result;
  my ($apikey) = $self->teams();

  return(0)
      if ($haveTeams ne 'yes');

#  $update = $self->subject
#      if ($self->teamsskiphost ne '');

  $self->logging('Notify: sendteams('.$update.')')
      if ($self->debug>2);

  $self->logging('Notify: teams key: '.$apikey)
      if ($self->debug>2);

  $update .= ' '.`date`
      if ($self->debug>2);

# curl -X POST -H 'Content-type: application/json' --data '{"text":"Hello, World!"}' https://teams.microsoft.com/l/channel/19%3a48286999b8c64a6e976ba0500b2900a4%40thread.skype/ATX-Monitor?groupId=89b12ed9-d4ce-4ca2-89fb-dccef8c08db2&tenantId=1eacbc7c-84ea-477e-9e93-49ca7ab5a6ba

  my $uri = $apikey;
  my $json = '{"text":"' . $update . '"}';
  my $req = HTTP::Request->new( 'POST', $uri );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json );

  my $lwp = LWP::UserAgent->new;
  my $response = $lwp->request( $req );
  my $content  = $response->decoded_content();

  if ( my $err = $@ ) {
      $self->logging('Notify: teams error')
  }
  
  return(1);
}


sub sendpage {
  my $self = shift;
  my $msg = shift;

  return(0)
      if ($havePager ne 'yes');

  my $syscall = $self->pager.' -f '.$self->hostname.' -p '.$self->page." \"$msg\"";
  system($syscall);
  if ($?>>8) {    # error in system call
    $self->logging("Error in system call for: \"$syscall\"");
    return;
  }
  if ($self->debug > 2) {
    $self->logging("  sendpage() ".ref($self)."->sendpage: $syscall");
  }
  return(1);
}

sub startlog {
  my $self = shift;
  my @nice;
  my($facility, $lvl)=split(/:/, $self->sysloglvl);
  if ((! defined $facility) or (! defined $lvl)) {
    push(@nice, 'sysloglvl');
  }
  push(@nice, 'syslogid') if (! defined $self->syslogid);
  if ($#nice>=0) {
    carp("need ".(join(', ', @nice))." defined correctly to use syslog");
    $self->{_OKAYTOLOG} = 0;
    return;
  }
  $self->{_LOGFACILITY} = $facility;
  $self->{_LOGLEVEL} = $lvl;
  if ($self->debug>2) {
    warn("  startlog(): openlog (".$self->syslogid.", \"cons,pid\", ".$self->{_LOGFACILITY}.")\n");
  }

  if (defined $self->syssock) {
    setlogsock($self->syssock);
  }
  openlog ($self->syslogid, 'cons,pid', $self->{_LOGFACILITY});
  syslog($self->{_LOGLEVEL}, '%s starting', $self->syslogid);
  $self->{_OKAYTOLOG} = 1;
  return;
}

sub logging {
  my $self = shift;
  if (! $self->{_OKAYTOLOG}) {
    carp "Logging not initialized properly";
    return;
  }
  my $lvl = shift;
  my $msg = shift;
  if (! defined $msg) {
    $msg = $lvl;
    $lvl = $self->{_LOGLEVEL};
  }
  syslog($lvl, $msg);
  if ($self->debug>2) {
    carp "  logging() ".ref($self)."->logging: $lvl, $msg";
  }
  return;
}

sub debug {
  my $self = shift;
  my $level = shift;
  if (! defined $self->{_DEBUG}) {
      $self->{_DEBUG} = $Debugging;
  }
  if (defined $level) {
      $self->{_DEBUG} = $level;
  }
  return $self->{_DEBUG};
}

# What you just said, is one the most insanely idiotic things I've every heard.
# At no point in your rambling, incoherent response, 
# were you even close to anything that could be considered a rational thought.
# Everyone in this room is now dumber for having listen to it.
  
1;
