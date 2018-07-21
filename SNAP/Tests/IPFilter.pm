package SNAP::Tests::IPFilter;

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.1';

# put any modules you want to use here:

my $lastmax = 0;
my $lastbkt = 0;

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  if (! $self->{cmd}) {
      $self->{cmd} = '/usr/sbin/ipfstat -s';
  }
  $self->logging(ref($self).': Monitoring ipfilter through: '.$self->{cmd});
  return $self;
}
  
sub test {
    my $self = shift;
    my @fhosts;
    my $action = $self->{cmd}.'|';

    $self->logging('starting test with:'.$action)
	if ($self->debug);

    open(DMP, "$action");

    my $use = '';
    my $pct = '';
    my $max = '';
    my $bkt = '';

    while(<DMP>) {
	chop;
	my $line = $_;

	if ($line =~ /(\d+) in use/) {
	    # these are the number of state entries (compare to IPSTATE_SIZE)
	    $use = $1;
	} elsif ($line =~ /(\d+\.\d+)\% bucket usage/) {
	    # the percentage of entries used ($use / IPSTATE_SIZE)
	    $pct = $1;
	} elsif ($line =~ /(\d+) bucket full/) {
	    # times the kernel found no free buckets
	    $bkt = $1;
	} elsif ($line =~ /maximum rule references/) {
	    # skip this or it gets picked up below
	} elsif ($line =~ /(\d+) maximum$/) {
	    # if this gets to be anything other than zero, you're in over your head.  game over
	    $max = $1;
	}
    }
    close(DMP);

# maybe track this as an incremental?
    if ($max > $lastmax) {
	push @fhosts, 'BOOM!';
	$lastmax = $max;
    }

    if ($pct > 70) { # the 70 comes as a convention found in FAQs
	push @fhosts, 'Warn:'.$pct.'%,'.$use;
    }

    if ($bkt > $lastbkt) {
	push @fhosts, 'Bkts:'.$bkt;
	$lastbkt = $bkt;
    }

    $self->logging("about to report: max=$max use=$use pct=$pct bkt=$bkt")
	    if ($self->debug);
	
    if ($#fhosts>=0) {
	$self->logging('Failed on '.($#fhosts+1).' hosts, returning with error');
	$self->ErrorString('IPFilter '.(join(', ', @fhosts)).'.');
	return;
    } else {
	$self->logging('returning normally') if ($self->debug);
	return 1;   # test passed
    }
}

1;
