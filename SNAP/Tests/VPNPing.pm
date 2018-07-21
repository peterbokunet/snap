package SNAP::Tests::VPNPing;

use SNAP::Test;
use vars qw(@ISA $VERSION);
our @ISA = qw(SNAP::Test);	
my $VERSION='1.2';

use strict;

# put any modules you want to use here:
use Net::Ping;
use IO::Socket;

my $ltime = 0;
my %vhosts;

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    $self->logging("Resetting VPN peers at $self->{peer} on $self->{vport} for: $self->{dest}");
    return $self;
}

sub test {
    my $self = shift;
    my @fhosts;
    my @rhosts;

    $self->logging('->test()')
	if ( $self->debug);

    my $lnow = time % 3600;
    my $nag = ($lnow < $ltime) ? 'YES' : 'NO';
    $ltime = $lnow;

    my $p=Net::Ping->new('icmp', $self->{timeout});
    $p->bind($self->{laddr}) if (defined $self->{laddr});
    foreach my $cur (split(/[\s+,]+/, $self->{hosts})) {
	my $host;
	my $cycles;
	my $state;

	($host, $cycles) = split(/:/, $cur);
	$cycles = 6
	    if ($cycles eq '');
	if (! defined $vhosts{$host}) {
	    $self->logging("Presuming $host is UP")
		if ($self->debug);
	    $vhosts{$host} = 'UP';
	    $vhosts{"$host cycles"} = $cycles;
	}

	$self->logging("testing: $host")
	    if ($self->debug);

	if (! $p->ping($host)) {
	    $self->logging("Failed to ping $host")
		if ($self->debug);
	    $self->logging("Failed to ping ".$host);
	    # at this point we know we're not UP.
	    # the only thing we know is that we're DWN
	  
	    $state = 'DWN';
	    
	    # increment cycles
	    $vhosts{"$host cycles"}++;
	    $self->logging('Cycles for '.$host.' is now: '. $vhosts{"$host cycles"})
		if ($self->debug > 9);
	    
	    if ($vhosts{"$host cycles"} > $cycles) {
		# We don't want to pound on racoon, so we'll only reset the
		# peer every so often.  The 'cycles' paramter let's us manage
		# our way through this.  Some peers do need to be unstuck at
		# times.
		$self->resetpeer($host);
		$state = 'RST';
		$vhosts{"$host cycles"} = 0;

		# at this point we need to fire off a packet to bring the
		# freshly reset session back up.  In TCP land the stack will
		# dribble off a lingering packet but this ICMP test is a
		# one for one delivery.  With this in mind, see if we can
		# bring it back up, but don't care if it worked or not.

		$p->ping($host);
    	    }
	} else {
	    $self->logging("Succeeded pinging $host")
		if ($self->debug > 2);
	    $state = 'UP';
	    $vhosts{"$host cycles"} = $cycles;
	}
	
	$self->logging("about to report: host=$host vhosts=$vhosts{$host} state=$state nag=$nag cycles=".$vhosts{"$host cycles"})
	    if ($self->debug);
	
	if ($state ne 'RST') {
	    # don't alert anything, regardless if it's UP or DWN
            # we're in this limbo land where we might be back up or
	    # might still be down
	    
	    if (($vhosts{$host} ne $state) || (($nag eq 'YES') && ($state ne 'UP'))) {
		# we have a new state (meaning it's UP or DWN)
		# or it's time to nag
		
		push @fhosts, "$host:$state";
		$self->logging('adding: '.$host.':'.$state)
			if ($self->debug);
	    }
	    $vhosts{$host} = $state;
	}
    }

    if ($#fhosts>=0) {
	$self->logging("Failed on ".($#fhosts+1)." hosts, returning with error");
	$self->ErrorString('VPN!H '.(join(', ', @fhosts)).'.');
	return;
    } else {
	$self->logging("returning normally") if ($self->debug);
	return 1;   # test passed
    }
}

sub resetpeer {
    my $self = shift;
    my $peer = shift;
    
    if ((defined $peer) && ($peer != '')) {
        return $self;
    }
    
    my $sock = new IO::Socket::INET (
				     PeerAddr => $self->{peer},
				     PeerPort => $self->{vport},
				     Proto => 'tcp',
				     );
    if (defined $sock) {
	select($sock); $| = 1;
        print $sock "$peer\n";
        sleep(4);
        close($sock);
    } else {
        $self->logging("VPNPing Failed to connect to: $self->{peer}:$self->{vport}");
    }
    return $self;
}

1; # this must be here

