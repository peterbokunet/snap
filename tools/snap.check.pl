#!/usr/local/bin/perl5

use lib '/usr/snap';
use SNAP::Notify;

close(STDERR);
open (STDERR, ">/dev/null");
my $me = 'ncc';
my $ntfy = new SNAP::Notify(mail => 'alarms@cake',
                        mailer => '/usr/sbin/sendmail -t',
                        page => 'noc',
                        pager => '/usr/local/bin/qpage',
                        sysloglvl => 'local2:debug',
                        syslogid => 'snap.check',
                        from => 'root@ncc',
                        subject => 'SNAP run checker, errors',
			signature => "This is created from ncc:/usr/snap/tools/snap.check.pl\n",
                        hostname => $me);

my @hosts = split(/\s+/, `/usr/tools/bin/snap_hosts`);


my (@badhosts);
my (@unk);
my $res;
foreach (@hosts) {
    $res = running($_);
      #  undef = everything ok
      #  1 = not running 
      #  2 = unknown state
      #  3 = unknown line returned
      #  4 = subsystem not on file
    next if (! defined $res);
    if ($res == 1) {
	# print "Not running on $_\n";
	push(@badhosts, $_);
    } elsif ($res == 2) {
	# print "Unknown state on $_\n";
	push(@unk, $_);
    } elsif ($res == 3) {
	# print "Unexpected response from $_\n";
	push(@unk, $_);
    } elsif ($res == 4) {
	# print "snap is not defined on $_\n";
	push(@unk, $_);
    } elsif ($res == 5) {
	# print "Could not connect to $_\n";
    } elsif ($res == 6) {
	# print "Unknown Error on  $_\n";
    } else {
	print "weird: got back \'$res\' on $_\n";
    }
}
my $error='';
$error = "Snap not running on ".(join(', ', @badhosts)) if ($#badhosts>=0);
my $unknown='';
$unknown = "Unknown state of snap on ".(join(', ', @unk)) if ($#unk>=0);

my $pg;
if ((length($error)) && (length($unknown))) {
  $pg = $error."; ".$unknown;
} else {
  $pg = $error.$unknown;
}

$ntfy->sendmail($pg) if (length($pg));
$ntfy->logging('info', "ncc -> ".$pg) if (length($pg));

sub running {
  #  undef = everything ok
  #  1 = not running 
  #  2 = unknown state
  #  3 = unknown line returned
  #  4 = subsystem not on file
  #  5 = error running rsh
  my $host = shift;
  my @badhost;
  if (! open(T, "/usr/bin/rsh $host \'/usr/bin/lssrc -s snap\'|")) {
    print "Could not run rsh to $host\n";
    return(5);
  }
  chop($line=<T>);
  if ($line=~/Subsystem is not on file/) {
    return(4);
  } elsif ($line=~/Subsystem\s+Group\s+PID\s+Status/) {
    while (defined ($line=<T>)) {
      if ($line=~/^\s*snap/) {
	if ($line=~/active\s*$/) {
	  return;
        } elsif ($line=~/inoperative\s*$/) {
	  return(1);
        } else {
	  return(2);
	}
      } else {
	  return(3);
      }
    }
  }
  close(T);
  if ($?>>8) {
     return(5);
  }
  return(6);
}
