
!!! This is very AIX centric !!!



This is an email between Jazz and myself, about how to setup
snap on new boxes, I thought it'd be a good idea to stick this
into the snap distribution...

Date: Tue, 16 Nov 1999 15:03:31 -0600 (CST)
From: Jay Jacobs <jay@noc.harmonic.com>
To: John Jaszczak <jjaszczak@mail.harmonic.com>
Subject: Re: snap on new systems

For new systems the key components are the [Ping] section and [Diskspace]
section...
[Ping]
hosts=cac,dup-rtr,ewing,bulky
...

[Diskspace]
ignore=/dev/cd0,/usr/local/lowspace/normal
defaultspace=20000

# the ignore can be either device name or mount point, and each mount
point can have a value in either a percentage or hard number (in k)

hosts can be any hosts or IP, seperated with a command and optional white
space (cac,ewing is the same as cac, ewing).

The [Selfcheck] section should be the same across all systems:
[Selfcheck]
lookfor = /tmp/snap.findme
ackfile = /tmp/roger.dodger.snap

This is a test run from ncc that makes sure that snap is functioning (not
just listed in process list)

[Netxmon] takes only one argument, how to run netx_lookup

[Procerr] takes a 'grepfor' and 'tlogdir', which should be the same on all
netx hosts.

The [TestMC] and [TestHRSI] aren't really in use (on a few systems
perhaps).  But are kinda self-explanatory.

The [Rimwatch] section could be defined (same on all) if the connecting
rims aren't persistant connections.

And oh yeah, the [main] section should be the same, if snap is logging too
much we should set debug=0.

I've just been grabbing someone else's config (/usr/snap/masters) and
modifying for that host.

Keep in mind, I've got a script that will overwrite the snap.conf on a
remote host if it's different from the version on ncc in
/usr/snap/masters.  So any permanent changes to snap.conf should be
replicated to /usr/snap/masters/<host>.snap.conf - where <host> matches
the hostname in /usr/tools/bin/snap_hosts.

I should probably copy this email into a README file...

Jay

On Tue, 16 Nov 1999, John Jaszczak wrote:

> Ya, Ya!
>   This is what I was looking for. If you have some time this afternoon
> (before 3PM)
> or tomorrow morning, could you stop by and give me the once over for
> configuring snap? I'd like to be able to incorporate the set-up into a
> script so stuff doesn't get forgotten when doing new boxes.
>   I guess I'm looking for specifc parameters to be concerned with in the
> conf file.
> 
> -JAZZ
> -----Original Message-----
> From: Jay Jacobs <jay@cake.harmonic.com>
> To: John Jaszczak <jjaszczak@mail.harmonic.com>
> Date: Tuesday, November 16, 1999 1:34 PM
> Subject: Re: snap on new systems
> 
> 
> >For a new box, take ncc:/usr/snap/
> >don't take /usr/snap/tools or /usr/snap/masters (But do take the SNAP/ and
> >subsequent directories)
> >
> >The snap.conf file will need to be modified for the specific host, then
> >copied back into /usr/snap/masters on ncc, and the host added into
> >ncc:/usr/tools/bin/snap_hosts
> >
> >syslog will need local2.debug to a file, and local2.debug to @cake.
> >
> >The command to add snap into the SRC is a comment in the main snap app:
> ># mkssys -s snap -p /usr/snap/snap -u 0 -S -n 30 -f 31 -G hsinoc
> >
> >It should have the current perl libs (from hey).
> >
> >It should also have qpage done:
> >I compiled three versions (on ncc) of the 3.3 release, which look for an
> >executable (/usr/local/bin/qpage.noc) which is a perl script that sends
> >any page for noc to local2.info (subsequently cake).  If it doesn't find
> >qpage.noc it pages as normal.
> >
> >Full listing of files:
> >/usr/snap/SNAP/Config.pm
> >/usr/snap/SNAP/Notify.pm
> >/usr/snap/SNAP/Test.pm
> >/usr/snap/SNAP/Tests/Diskspace.pm
> >/usr/snap/SNAP/Tests/Netxmon.pm
> >/usr/snap/SNAP/Tests/Ping.pm
> >/usr/snap/SNAP/Tests/Procerr.pm
> >/usr/snap/SNAP/Tests/Rimwatch.pm
> >/usr/snap/SNAP/Tests/TestENQ.pm
> >/usr/snap/SNAP/Tests/TestHRSI.pm
> >/usr/snap/SNAP/Tests/TestMC.pm
> >/usr/snap/SNAP/Tests/Selfcheck.pm
> >/usr/snap/SNAP/Tests/Procerr.pm.ver1
> >/usr/snap/time.pl
> >/usr/snap/README.conf
> >/usr/snap/snap
> >/usr/snap/snap.conf
> >/usr/snap/restart.snap
> >/usr/snap/README.snap
> >/usr/snap/pingwho.pl
> >
> >/usr/local/bin/qpage.noc
> >/usr/local/bin/qpage.README.noc
> >/usr/local/bin/qpage (dynamic link to one of: )
> >/usr/local/bin/qpage-3.3-3.2.5
> >/usr/local/bin/qpage-3.3-4.2.1
> >/usr/local/bin/qpage-3.3-4.3.2
> >
> >Is that what you were looking for?
> >
> >Jay
> >
> >
> >
> >
> >On Tue, 16 Nov 1999, John Jaszczak wrote:
> >
> >> Jay,
> >>   I'm tweaking the script I have for setting up new servers. At present
> it
> >> sets up syswatch. What should I grab and do to have it use "snap"
> instead?
> >> i.e. which binaries, what config file, what install script.....
> >>
> >> -JAZZ
> >> John Jaszczak                         Assigned To:.
> >> Romac International                 Harmonic Systems, Inc.
> >> 8500 Normandale Lake Blvd   701 4th Ave S., Suite 1600
> >> Bloomington, MN 55437          Minneapolis, MN 55415
> >> 612-321-4139                          jjaszczak@harmonic.com
> >>
> >
> 

