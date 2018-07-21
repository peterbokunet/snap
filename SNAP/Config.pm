package SNAP::Config;

use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  # return if ($#_ < 0);
  my $self = {
    "pathname"  => shift,
    "section"  => {},
  };
  bless $self, $class;
  if ( ($self->load()) == 0 ) {
    return;
  }
  return $self;  
}

sub load {
  my ($self) = shift;
  my $section = undef;
  if (! open (CONF, $self->pathname)) {
    print "Cannot open config file: $!\n";
    return;
  }
  while (<CONF>) {
    chomp;
    (s/^\s*//); # remove leading whitespace
    next if ((length($_)<1) || (/^\s*(\#|\;)/)); # skip empty or comment lines
    $_ = (split(/\#|\;/, $_))[0] if (/\#|\;/);  # removes trailing comments
    if (m/^\[\s*(\S*)\s*\]/) {    # found a section
      $section = $1;
      $self->value($section, undef, undef)
	 unless ($section=~m/^main$/);
      next;
    } elsif (! defined $section) {
      next;
    } elsif (m/^([\w\/]+)\s*=\s*(.*)/) {
      my $key = $1;
      (my $value = $2) =~ s/\s+$//;
      if ($section=~m/^main$/) {
	$self->mainvalue($key, $value);
      } else {
        $self->value($section, $key, $value);
      }
    } else {
      my $key = split;  # splits on whitespace, takes first 'word'
      if ($section=~m/^main$/) {
	$self->mainvalue($key, undef);
      } else {
	$self->value($section, $key, undef);
      }
    }
  } 
  close CONF;
  return 1;
}

sub pathname {
  my $self = shift;
  if (@_) { $self->{pathname} = shift }
  return $self->{pathname};
}

sub DESTROY {
  return;
}

sub mainvalue {
  my $self = shift;
  my $key = shift;
  my $value = shift;
  return if (! defined $key);
  $self->{$key} = $value if (defined $value);
  return($self->{$key});
}

sub getsection {
  my $self = shift;
  my $section = shift;
  return %{$self->{section}{$section}};
}

sub value {
  my $self = shift;
  my $section = shift;
  my $key = shift;
  my $value = shift;
  if (defined $value) {
    $self->{section}{$section}{$key} = $value;
  } elsif ((! defined $key) && (defined $self->{section}{$section})) {
    return 1;
  }
  if (! defined $self->{section}{$section}{$key}) {
    return;
  } else {
    return($self->{section}{$section}{$key});
  }
}

sub sections {
  my $self = shift;
  return wantarray ? (keys %{$self->{section}}) : scalar (keys %{$self->{section}});
}

1;
