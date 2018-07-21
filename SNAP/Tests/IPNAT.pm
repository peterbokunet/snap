package SNAP::Tests::IPNAT;

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.1';

# put any modules you want to use here:

my $lastmem = 0;
my $lastbad = 0;

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  if (! $self->{cmd}) {
      $self->{cmd} = '/usr/sbin/ipnat -s';
  }
  $self->logging(ref($self).': Monitoring ipnat through: '.$self->{cmd});
  return $self;
}
  
sub test {
    my $self = shift;
    my @fhosts;
    my $action = $self->{cmd}.'|';

    $self->logging('starting test with:'.$action)
	if ($self->debug);

    open(DMP, "$action");

    my $use = 0;
    my $mem = 0;
    my $bad = 0;
    my $unused;

    while(<DMP>) {
	chop;
	my $line = $_;
	
	if ($line =~ /inuse(\s)(\d+)/) {
	    $use = $2;
	} elsif ($line =~ /memory(\s)(\d+)(\s)bad nat(\s)(\d+)/) {
	    ($unused, $mem, $unused, $bad) = split(/\t/, $line);
	}
    }
    close(DMP);

    # maybe track this as an incremental?
    if ($mem > $lastmem) {
	push @fhosts, 'NO MEM';
	$lastmem = $mem;
    }

    if ($bad > $lastbad) {
	push @fhosts, 'Bad:'.$bad;
	$lastbad = $bad;
    }

    $self->logging("about to report: mem=$mem use=$use bad=$bad")
	if ($self->debug);
	
    if ($#fhosts>=0) {
	$self->logging('Failed on '.($#fhosts+1).' hosts, returning with error');
	$self->ErrorString('IPNAT '.(join(', ', @fhosts)).'.');
	return;
    } else {
	$self->logging('returning normally') if ($self->debug);
	return 1;   # test passed
    }
}

1;
