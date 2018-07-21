#!/usr/local/bin/perl5

use lib '/usr/snap';
use SNAP::Notify;

my $me = 'ncc';
my $ntfy = new SNAP::Notify(mail => 'noc@cake',
                        mailer => '/usr/sbin/sendmail -t',
                        page => 'noc',
                        pager => '/usr/local/bin/qpage',
                        sysloglvl => 'local2:debug',
                        syslogid => 'snap.reload',
                        from => 'root@ncc',
                        subject => 'SNAP Package-sync error',
			signature => "This is created from ncc:/usr/snap/masters/snap.package.pl",
                        hostname => $me);

# my @hosts = split(/\s+/, `/usr/tools/bin/snap_hosts`);
my @hosts;
push (@hosts, "uds1", "dia1", "shr2");

my $rdistfile = "/usr/snap/tools/snap.package.rdist";
my $rdistlog = "/usr/snap/tools/snap.package.log";

if (! open (T, ">$rdistfile")) {
  $ntfy->sendmail("Could not open $rdistfile for writing.\nexitting without updating package\n");
  exit(1);
}
print T "HOSTS = ( ".(join(' ', @hosts))." )\n";
print T "FILES = ( /usr/snap )\n";
print T '${FILES} ->${HOSTS}'."\n";
print T "  install -R ;\n";
print T "  except /usr/snap/snap.conf ;\n";
print T "  except /usr/snap/tools ;\n";
print T "  except /usr/snap/masters ;\n";
print T "  except /usr/snap/.rimwatch ;\n";
print T "  except /usr/snap/snap.err ;\n";
print T "  notify jay\@cake ;\n";
close(T);

my $cmd = '/usr/bin/rdist -f '.$rdistfile.' > '.$rdistlog;
system($cmd);
if ($?>>8) {
    $ntfy->sendmail("Bad Return status from running $cmd");
    exit(1);
}
if (! unlink ($rdistfile)) {
    $ntfy->sendmail("Could not unlink $rdistfile");
}
exit(0);
