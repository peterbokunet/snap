"snap" stands for "System & Network Analysis Program", a name with little
significance other than not being "sys_watch" or "mondo" or any of the
publicly available tools.

This is written and currently maintained by Jay Jacobs
(jay@iamnotavergin.com).

When snap is started, it will load up a configuration file, currently
hardcoded to be "/usr/snap/snap.conf".  After loading up and interpreting
the configuraiont file (see README.conf), it will load up and initialize
the notification methods.  Unfortunately, the Sys::Syslog perl module is
quite poor for error checking, so that should be checked by hand upon
installing.

The directory structure and files are:

./snap/
    main directory
./snap/snap
    main executable
./snap/snap.conf
    configuration file
./snap/restart.snap
    calls stopsrc and startsrc to restart the snap app.
./snap/SNAP/
    main library/module directoy
./snap/SNAP/Notify.pm
./snap/SNAP/Config.pm
./snap/SNAP/Test.pm
    The Test.pm is the parent Test module.  All of the defined tests in
snap will use this parent to create a standard instance of it's test
object.
./snap/SNAP/Tests/
    Directory holding all of the test modules.

SRC control:
    snap is intergrated into the Aix System Resource Controller.  It can
be started, stopped or checked with 'startsrc', 'stopsrc', and 'lssrc',
respectively.  The arguments can be either '-s snap' to specificy the snap
process, or '-g hsinoc' to specify the hsinoc group to which snap belongs.

For questions on specific Tests, or modules, look in the directory that
they reside in for their README (working on it now).

Jay Jacobs
October 13, 1999
