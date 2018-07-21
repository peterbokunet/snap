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

my @badhosts;
foreach (@hosts) {
  my $temp = "/usr/bin/rsh $_ \'/usr/snap/restart.snap\'";
  system($temp);
  if ($?>>8) {
    print "Bad: $_\n";
    push(@badhosts, $_);
    next;
  } else {
    print "Good: $_\n";
  }
}

my $str;
if ($#badhosts>=0) {
  $ntfy->subject("SNAP restart report");
  $str = "The following hosts could not be started by /usr/snap/tools/restart.all.pl:\n".(join(', ', @badhosts)).".\n";
  $ntfy->sendmail($str);
}
