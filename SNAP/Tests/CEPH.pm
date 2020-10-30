package SNAP::Tests::CEPH;

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.1';

# put any modules you want to use here:

my $lastmem = 0;
my $lastbad = 'HEALTH_OK';

sub new { 
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  if (! $self->{cmd}) {
      $self->{cmd} = '/usr/bin/ceph health';
  }
  $self->logging(ref($self).': Monitoring ceph through: '.$self->{cmd});
  return $self;
}
  
sub test {
    my $self = shift;
    my @fhosts;
    my $action = $self->{cmd}.'|';

    $self->logging('starting test with:'.$action)
	if ($self->debug);

    open(DMP, "$action");

    my $health = 'HEALTH_OK';

    while(<DMP>) {
	chop;
	my $line = $_;
	
#	if ($line =~ /health: (\S+)/) {
#	    $health = $1;
#	}
	$health = $line;

	$self->logging('found line: '. $line .' <== '. $health) if ($self->debug > 5);
    }
    close(DMP);
    
    # maybe track this as an incremental?
    if ("$health" ne "$lastbad") {
	push @fhosts, 'Status:'.$health;
	$lastbad = $health;
    }

    $self->logging("about to report: health=$health; lastbad=$lastbad")
	if ($self->debug);
	
    if ($#fhosts>=0) {
	$self->logging('Failed on '.($#fhosts+1).' hosts, returning with error');
	$self->ErrorString('CEPH '.(join(', ', @fhosts)).'.');
	return;
    } else {
	$self->logging('returning normally') if ($self->debug);
	return 1;   # test passed
    }
}

1;

