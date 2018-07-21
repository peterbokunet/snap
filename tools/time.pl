#!/usr/local/bin/perl5

my $cmd = "grep -i snap /usr/syslog/snap |";


my ($wtotal, $with, $wlo, $whigh) = 0;
my ($ototal, $out, $olo, $ohigh) = 0;
$olo = $wlo = 1000;
open (C, $cmd);
while (<C>) {
    next unless (/TIME: (\d+) seconds \((with|no)/);
    my $t = $1;
    my $er = $2;
    if ($er=~/with/) {
	$wtotal += $t;
	$with++;
	$wlo = $t if ($t < $wlo);
	$whigh = $t if ($t > $whigh);
    } else {
	$ototal += $t;
	$out++;
	$olo = $t if ($t < $olo);
	$ohigh = $t if ($t > $ohigh);
    }
}

printf("\n  %10s  :  %-4s %-4s\n", "Errors", " Y", " N");
printf("  %10s  :  %-4d %-4d\n", "High", $whigh, $ohigh);
printf("  %10s  :  %-4d %-4d\n", "Low", $wlo, $olo);
unless ($with==0 || $out==0) {
  printf("  %10s  :  %-4d %-4d\n", "Average", (int($wtotal/$with)), (int($ototal/$out)));
}
printf("  %10s  :  %-4d %-4d %6d samples\n\n", "Total", $with, $out, ($with+$out));
