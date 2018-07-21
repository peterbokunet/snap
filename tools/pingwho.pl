#!/usr/local/bin/perl5

use Socket;
use Net::Ping;

syswrite(STDOUT, "Looking for hosts in Netx Profile... ", 37);
if (! open (G, "/usr/netx/bin/netx_save_prf Z|")) {
  print STDERR "couldn't run netx_save_prf\n";
  exit;
}
while (<G>) {
   if (/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
	$host =gethostbyaddr((inet_aton($1)), AF_INET);
	# print "$1\t$host\n";
	$hosts{$host} = 1;
    }
}
my $count = 0;
foreach (keys %hosts) {
  $count++;
}
print "pulled out $count hosts\n";

  my $p=Net::Ping->new('icmp', 5);
  foreach $host (keys %hosts) {
    if (! $p->ping($host)) {
      push @fhosts, $host;
    } else {
      push @ghosts, $host;
    }
  }
  if ($#fhosts>=0) {
    print "\nCould not ping these hosts:\n";
    print (join(', ', @fhosts));
    print "\n";
  }

  print "\nCould ping these hosts:\n";
  print (join(', ', @ghosts));
  print "\n";
  
