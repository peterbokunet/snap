#!/usr/local/bin/perl5

use lib '/usr/snap';
use SNAP::Notify;

if ($ARGV[0]=~/[\-h\?]+/) {
  print "usuage: $0 <-f>\n    -f (optional) force the restarting of snap on all hosts\n";
  exit(0);
}

my $me = 'ncc';
my $ntfy = new SNAP::Notify(mail => 'alarms@cake',
                        mailer => '/usr/sbin/sendmail -t',
                        page => 'noc',
                        pager => '/usr/local/bin/qpage',
                        sysloglvl => 'local2:debug',
                        syslogid => 'snap.reload',
                        from => 'root@ncc',
                        subject => 'SNAP reload snap.conf file ',
			signature => "This is created from ncc:/usr/snap/tools/reload.all.pl\nWhere all of the snap.conf master files are stored to maintain\nconfiguration integrity (good word huh?)",
                        hostname => $me);

my @hosts = split(/\s+/, `/usr/tools/bin/snap_hosts`);
my $rdistfile = "/usr/snap/tools/reload.all.rdist";
if (! open (T, ">$rdistfile")) {
  $ntfy->subject("SNAP reload snap.conf ERROR");
  $ntfy->sendmail("Could not open $rdistfile for writing.\nexitting without reloading conf files\n");
  exit(1);
}

my $src;
my @badhosts;
foreach (@hosts) {
  $src = "/usr/snap/masters/".$_.".snap.conf";
  if ( -e $src ) {
    print T "$src -> $_\n";
    print T "  install /usr/snap/snap.conf ;\n";
    if ($ARGV[0] eq "-f") {
      print T "  special \"/usr/snap/restart.snap\" ;\n\n";
    } else {
      print T "  special $src \"/usr/snap/restart.snap\" ;\n\n";
    }
  } else {
    push(@badhosts, $_);
  }
}

close(T);

my $cmd = "/usr/bin/rdist -f $rdistfile|";
if (! open(R, $cmd)) {
    $ntfy->subject("SNAP reload snap.conf ERROR");
    $ntfy->sendmail("Could not execute $cmd");
    exit(1);
}
my $msg;
$msg = "Hosts without snap.conf files:\n".(join(', ', @badhosts))."\n\n" if ($#badhosts>=0);
while(<R>) {
    $msg .= "reloaded snap.conf on $1 to original config\n" if (/updating: ([^\.]+)\.snap\.conf/);
}
close(R);
$ntfy->sendmail($msg) if (length($msg));
unlink ("$rdistfile");
exit(0);
