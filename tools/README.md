This is a description of the tools in this directory.

README
  This file.

The following files will read /usr/local/bin/snap_hosts
to determine what hosts to touch.

reload.all.pl
  This will tranfer the master config file for the specific host
if and only if it needs it.  If it does transfer the orginal .conf
file, it will then call /usr/snap/restart.snap on the remote
system, thus restarting snap.

restart.all.pl
  This will call /usr/snap/restart.snap on all the boxes, thus
restarting snap at all locations.

snap.check.pl
  This coincides with the "Selfcheck" test in snap.  It will put
a file on the remote system containing time() output.  Then it will
wait for 3 minutes and go back to see if snap has removed the file
and created an ack file with the same contents as the original file.

snap.package.pl
  This will check and update the source code for snap, excluding the
snap.conf file.  It will not restart it, though it probably should
soon.

snap.running.pl
  This tests if snap is listed as running according to the lssrc 
command, if not it logs and mails.
