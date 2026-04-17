#!/usr/bin/perl

#  snap - System & Network Analysis Programj
#  October 1999, version 1.00 (yes, it's y2k)
#  Jay Jacobs
#
#  there should be README files all over the directory structure.
#
#  If you're using Net::Ping in Tests::Ping.pm this will need to be
#  running as 'root'
#

##### BEGIN CONFIGURABLE ######
my $SNAPHOME='/opt/snap';
my $SNAPCONF="$SNAPHOME/snap.conf";
my $SNAPERRS='/tmp/snap.err';
##### END CONFIGURABLE ######

use lib '/opt/snap';
use SNAP::Config;
use SNAP::Log;
use SNAP::Notify;
use Data::Dumper;

use strict;
my $VERSION = '1.20';

# a way to catch errors:
close(STDERR);
open (STDERR, ">$SNAPERRS");

# needed for AIX integration:
# mkssys -s snap -p $SNAPHOME/snap -u 0 -S -n 30 -f 31 -G snap
$SIG{NORM} = sub { die NORMAL FORCE };

my $host = `hostname -s`;
chop($host);

my $cfg = SNAP::Config->new($SNAPCONF);
if (! defined $cfg) {
    print "Not defined Config: $!\n";
    print STDERR "Not defined Config: $!\n";
    exit(1);
}

my $log = SNAP::Log->new($cfg);
if (! defined $log) {
    print "Not defined Log: $!\n";
    print STDERR "Not defined Log: $!\n";
    exit(1);
}

# enable stdout when running under systemd (--no-fork)
my $nofork = grep { $_ eq '--no-fork' } @ARGV;
$log->enable_stdout() if $nofork;

my $notify = SNAP::Notify->new($cfg);
if (! defined $notify) { 
  print "Not defined Notify: $!\n";
  print STDERR "Not defined Notify: $!\n";
  # not exitting though.
}

# set and log some initial stuff:
$log->log("  hostname is now \'".$notify->hostname($host)."\'");
$log->log("  subject is now \'".$notify->subject("No subject set")."\'");
$log->log("  from is now \'".$notify->from('SNAP ('.$host.') <snap@'.$host.'>')."\'");
$log->log("  signature is now \'".$notify->signature("\nEnd of Message\n")."\'");

my @notifiers;

my $mod;
my $user;
my $booterrors = '';
my ($cmd, $test, @tests);

# loop through the sections in config file, try to load as a Notify module first,
# then as a Test module. This allows config sections like [Slack], [Teams], [Mail]
# to load SNAP::Notify::Slack, etc. and sections like [Ping], [Diskspace] to load
# SNAP::Tests::Ping, etc.
foreach ($cfg->sections) {
  my $nmod = "SNAP::Notify::$_";
  eval "use $nmod;";
  if (!($@ =~ /\w/)) {
    $log->log("  Success loading notify module '$nmod'.");
    my $n = $nmod->new($cfg);
    if (defined $n) {
      push @notifiers, $n;
      $log->log("  Loaded notifier: $nmod");
    }
    next;
  }

  $mod = "SNAP::Tests::$_";
  $user = "use ".$mod;
  $log->log("Attempting to load \'$user\'... ");
  eval $user;
  if ($@=~/\w/) {  # eval caught something
    my $error = $@;
    $booterrors .= " $mod did not load";
    $log->log("  ERROR: Could not Load $mod ($1)");
    $log->log("  ERROR: $error");
  } else {
    $log->log("  Success loading \'$mod\'.");
    $log->log("Attempting to call \'new\' method in $mod... ");
    $cmd = "push(\@tests, ".$mod."->new(\$cfg, \$log))";  # call new and push it 
    eval $cmd;
    if ($@=~/\w/) {
      print STDERR "ERROR: $@\n";
      $log->log("  ERROR: $@");
    } else {
      $log->log("  Success calling \'new\' in \'$mod\'.");
    }
  }
}

# my $overall = "snap restarted";  # initial message when started (blank for none)
my $overall = "snap restarted" . $booterrors;

# for debug purposes, setting this to a module name will dump out the module to stdout.
my ($dumpme) = "ZZZZTestENQ";

my $SNAPPID = $cfg->mainvalue('pidfile');
$SNAPPID = '/var/run/snap.pid'
    if (! defined $SNAPPID);

if (!$nofork) {
  my $pid = fork;
  if ($pid) { # parent: save PID
      open PIDFILE, ">$SNAPPID" or die "can't open $SNAPPID: $!\n";
      print PIDFILE $pid . "\n";
      close PIDFILE;
      exit 0;
  }
}

my $SNAPTIME = $cfg->mainvalue('cycletime');
$SNAPTIME = 120
    if (! defined $SNAPTIME);

while (1) {
  my $timer = time();
  foreach $test (@tests) {
    if (ref($test)=~$dumpme) {
      print "Dumping out ".ref($test).":\n";
      print Dumper $test;
    }
    if (! $test->test) { # test failed
      # dig the excessive (()) here.
      $log->log(((split(/::/, (ref($test))))[$#_])." reported: ".$test->ErrorString);
      if (length($overall)) {  # already a message in the overall report
	$overall.= "; ";
      }
      $overall.=$test->ErrorString();  # get errorstring from test
      $test->clearErrorString();       # then clear it out for next time
    } else {
      $test->clearErrorString();       # no error, but clear it anyway.
    }
  }
  if (length($overall)) {
      $overall = localtime . ' ' . $overall;
    $notify->subject($overall);        # set the subject to the message
    # dispatch to modular notifiers
    foreach my $n (@notifiers) {
      $n->hostname($host);
      $n->subject($overall);
      $n->from($notify->from);
      $n->signature($notify->signature);
      $n->send($overall);
    }
    my $formatted = sprintf("%10s -> %s", $host, $overall);
    $log->log("info", $formatted);
    $overall='';
    $log->log("TIME: ".(time()-$timer)." seconds (with Errors)");
  } else {
    $log->log("TIME: ".(time()-$timer)." seconds (no Errors)");
  }
  sleep $SNAPTIME;
}

exit;

