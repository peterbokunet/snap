# SNAP — System & Network Analysis Program

A lightweight, modular monitoring daemon written in Perl. SNAP runs periodic tests (ping, disk space, memory, etc.) and dispatches alerts through pluggable notification modules (Slack, Teams, email, pager).

## Quick Start

```bash
# Copy and edit the example config
cp snap.conf.new /opt/snap/snap.conf
vi /opt/snap/snap.conf

# Run in foreground (for testing)
perl snap.pl --no-fork

# Install as a systemd service
cp snap.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now snap
```

## Configuration

SNAP uses an INI-style config file. Section names map directly to module names:

- `[Slack]` loads `SNAP::Notify::Slack`
- `[Ping]` loads `SNAP::Tests::Ping`
- `[Memory]` loads `SNAP::Tests::Memory`

See `snap.conf.new` for a fully documented example.

### Minimal Config

```ini
[main]
debug = 0
cycletime = 120
sysloglvl = local2:debug
syslogid = snap
logfile = /dev/null

[Slack]
url = https://hooks.slack.com/services/YOUR/WEBHOOK

[Ping]
hosts = localhost,10.0.0.1
timeout = 5

[Memory]
threshold = 10240
```

## Architecture

```
snap.pl                  Main daemon — loads config, runs test loop, dispatches alerts
SNAP/Config.pm           INI config parser
SNAP/Log.pm              Logging (syslog, file, stdout)
SNAP/Notify.pm           Legacy notification handler (retained for compatibility)
SNAP/Notify/Base.pm      Base class for notification modules
SNAP/Notify/Slack.pm     Slack webhook notifications
SNAP/Notify/Teams.pm     Teams webhook notifications
SNAP/Notify/Mail.pm      Email via sendmail
SNAP/Notify/Pager.pm     Pager notifications
SNAP/Test.pm             Base class for test modules
SNAP/Tests/Ping.pm       ICMP ping monitoring
SNAP/Tests/Diskspace.pm  Disk space monitoring
SNAP/Tests/Memory.pm     Host memory monitoring (Linux + macOS)
SNAP/Tests/Selfcheck.pm  Self-check via marker file
SNAP/Tests/...           Additional test modules
```

### How It Works

1. `snap.pl` reads the config and loads modules matching each section name
2. Notification sections (`[Slack]`, `[Teams]`, etc.) load `SNAP::Notify::*` modules
3. Test sections (`[Ping]`, `[Memory]`, etc.) load `SNAP::Tests::*` modules
4. Every `cycletime` seconds, all tests run. Failures accumulate into an alert message
5. If any test fails, the message is dispatched to all loaded notification modules

### Writing a Test Module

Test modules inherit from `SNAP::Test`. Implement `test()` — return `1` for pass, `undef` for fail (set `ErrorString` with the failure message).

```perl
package SNAP::Tests::MyTest;
use SNAP::Test;
our @ISA = qw(SNAP::Test);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  bless $self, $class;
  return $self;
}

sub test {
  my $self = shift;
  if (something_is_wrong()) {
    $self->ErrorString("Something broke");
    return;
  }
  return 1;
}
1;
```

### Writing a Notification Module

Notification modules inherit from `SNAP::Notify::Base`. Implement `send($msg)`.

```perl
package SNAP::Notify::MyChannel;
use SNAP::Notify::Base;
our @ISA = qw(SNAP::Notify::Base);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  my $cfg = $_[0];
  $self->{url} = $cfg->value('MyChannel', 'url') if ref($cfg);
  $self->{_available} = defined $self->{url} ? 1 : 0;
  bless $self, $class;
  return $self;
}

sub send {
  my ($self, $msg) = @_;
  return 0 unless $self->{_available};
  # send $msg to your channel
  return 1;
}
1;
```

## Running Under systemd

The `--no-fork` flag keeps SNAP in the foreground and enables stdout logging, which is ideal for systemd:

```ini
# snap.service
[Unit]
Description=SNAP System Monitoring
After=network.target

[Service]
Type=simple
ExecStart=/opt/snap/snap.pl --no-fork
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
```

## History

SNAP was originally written by Jay Jacobs in October 1999 for AIX systems using the System Resource Controller (SRC). It has since been ported to Linux, macOS, and other Unix-like systems. The modular notification and logging systems were added in 2026.

## License

MIT License — see [LICENSE](LICENSE) for details.
