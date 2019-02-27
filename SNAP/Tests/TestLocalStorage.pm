package SNAP::Tests::TestLocalStorage;   # modify for your package name.
			      # must match SNAP/Tests/file.pm
			      # and [File] in config file must
			      # match, case sensitive.

use SNAP::Test;	      # parent app.
use vars qw(@ISA $VERSION);
@ISA = qw(SNAP::Test);	
$VERSION='1.0';

# put any modules you want to use here:
use IO::Select;

#Don't mess with this unless you know what you're doing.
sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;

    if (! defined $self->{prefix}) {
	$self->{prefix} = 'snap';
    }
    if (! defined $self->{data}) {
	$self->{data} = '005A0001001100CE02311C57495A3030301C31323334303030311C241C1C3236333630313030303030303332341C393931321C1C3830301C3132333435361C3834301C3834301C1C1C1C1C1C1C1C1C1C1C1C1C1C1C1C1C1C0372';
    }
    if (! defined $self->{directory}) {
	$self->{directory} = '/tmp';
    }
    return $self;
}
  
sub test {
  my $self = shift;
  $self->logging("starting test") if ($self->debug);
  my $time = time();

  my ($i, $wdata, $rdata, $filename, $retval);

  $wdata = $self->{data};
  $filename = sprintf('%s/%s%s', $self->{directory}, $self->{prefix}, $time);

  # never mess with an existing file
  if ( -e $filename) {
    $self->ErrorString('Scratch file exists: ' . $filename);
    $self->logging('will not overwrite: ' . $filename . ' return with error');
    return;
  }

  # open the file for writing
  if (! open(FILE, ">>$filename")) {
    $self->ErrorString('Error opening for writing: ' . $filename);
    $self->logging('could not create or append: ' . $filename . ' return with error');
    return;
  }

  # set the file i/o for binary
  if (! binmode FILE) {
    $self->ErrorString('Error setting file to binary: ' . $filename);
    $self->logging('could not set file to binary: ' . $filename . ' return with error');
    return;
  }

  # write to the file
  my $wbytes = syswrite(FILE, $wdata, length($wdata));
  if ($wbytes != length($wdata)) {
    $self->ErrorString('Error writinging byte length: ' . $filename . ' with buffer length: ' . length($wdata));
    $self->logging('Could not write buffer to file: ' . $filename . ' with length: ' . length($wdata) . ' return with error');
    return;
  }

  # close the file
  if (! close(FILE)) {
    $self->ErrorString('Error closing file: ' . $filename);
    $self->logging('could not close file: ' . $filename . ' return with error');
    return;
  }

  # sync linux buffer
  $retval = system('/bin/sync');
  if (($retval >>=8) != 0) {
    $self->ErrorString('Error syncing filesystem: ' . $filename . ' -> ' . $retval);
    $self->logging('error syncing filesystem: ' . $filename . ' return with error: ' . $retval);
    return;
  }
  $retval = system('/bin/echo 3 > /proc/sys/vm/drop_caches');
  if (($retval >>=8) != 0) {
    $self->ErrorString('Error flushing filesystem: ' . $filename . ' -> ' . $retval);
    $self->logging('error flushing filesystem: ' . $filename . ' return with error: ' . $retval);
    return;
  }

  # open the file for reading
  if (! open(FILE, "$filename")) {
    $self->ErrorString('Error opening for reading: ' . $filename);
    $self->logging('Could not open for reading: ' . $filename . ' return with error');
    return;
  }

  # read the full file
  $retval = sysread(FILE, $rdata, length($wdata));
  if (undef($retval)) {
    $self->ErrorString('Error reading file: ' . $filename);
    $self->logging('read failed with undef for file: ' . $filename . ' return with error');
    return;
  }

  if (($retval != 0) && ($retval != length($wdata))) {
    $self->ErrorString('Error reading file length: ' . $filename . ' expected/received: ' . length($wdata) . '/' . $retval);
    $self->logging('Error reading file length: ' . $filename . ' expected/received: ' . length($wdata) . '/' . $retval);
    return;
  }

  # test content of the buffer and the file
  if (!($wdata & $rdata)) {
    $self->ErrorString('Error read data does not match written data: ' . $filename . ' expected/received: ' . $wdata . '/' . $rdata);
    $self->logging('Error read data does not match written data: ' . $filename . ' expected/received: ' . $wdata . '/' . $rdata);
    return;
  }

  # close the file
  if (! close(FILE)) {
    $self->ErrorString('Error closing file: ' . $filename);
    $self->logging('could not close file: ' . $filename . ' return with error');
    return;
  }

  # delete the file
  if (! unlink($filename)) {
    $self->ErrorString('Error deleting file: ' . $filename);
    $self->logging('could not delete file: ' . $filename . ' return with error');
    return;
  }

  $self->logging('Wrote and read ' . length($wdata) . ' bytes in ' . (time()-$time) . ' sec') if ($self->debug);
  $self->logging('TestLocalStorage successful. return normally') if ($self->debug);
    return 1;
}

1; # this must be here
