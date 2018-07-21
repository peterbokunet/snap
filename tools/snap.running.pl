#!/usr/local/bin/perl5

use lib '/usr/snap';
use SNAP::Notify;

close(STDERR);
open (STDERR, ">/dev/null");
my $me = 'ncc';
my $ntfy = new SNAP::Notify(mail => 'noc@cake',
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

my $lookfor = '/tmp/snap.findme';
my $ackfile = '/tmp/roger.dodger.snap';

my (@badhosts);
my (@goodhosts);
my $t = time();
my $temp;
$temp = "/usr/bin/rsh <host> \'/bin/echo $t > $lookfor\'";
print "Attempting: $temp\n\n";
foreach (@hosts) {
  $temp = "/usr/bin/rsh $_ \'/bin/echo $t > $lookfor\'";
  system($temp);
  if ($?>>8) {
    print "Bad: $_\n";
    push(@badhosts, $_);
    next;
  } else {
    print "Good: $_\n";
    push(@goodhosts, $_);
  }
}

sleep 360;
  
my $ret;
$temp = "/usr/bin/rsh <host> \'/bin/cat $ackfile\'";
print "$temp\n\n";
foreach (@goodhosts) {
  $temp = "/usr/bin/rsh $_ \'/bin/cat $ackfile\'";
  chop($ret = `$temp`);
  if ($?>>8) {
    push(@badhosts, $_);
    next;
  }
  if ($ret != $t) {
    push(@realbad, $_);
    next;
  }
}

my $str;
if ($#realbad>=0) {
  $ntfy->logging('info', "SNAP possibly hung up on ".(join(', ', @realbad)));
  $ntfy->subject("SNAP running report");
  $str = "The following hosts may have stopped mid-process, check, and possibly restart:\n".(join(', ', @realbad)).".\n";
  if ($#badhosts>=0) {
    $str .= "The following were found to be unreachable: \n".(join(', ', @realbad)).".\n"
  }
  $ntfy->sendmail($str);
}
