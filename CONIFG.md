This is the README for the configuration file.

It is loaded upon start, and not looked at again.

Blank lines are ignored, as well as commented lines beginning with
the '#' symbol.  Lines can also contain comments at the end of the
line.

The configuration file is broken up into sections denoted by the 
[ <section> ] notation.  Also their is a reserved section name, 
"main" which puts the key/value pairs into a top level array.

Each section then contains key/value pairs seperated by an equal 
sign '='.  White space on either side of the equal sign is discarded.  
The key on the left side of the equal sign is expected to be one 
word (denoted by white space), containing A-Za-z0-9_/- characters.  
It should not begin with an _ (underscore) as that is reserved for 
internal variables.

The value on the right of the equal sign, does not need
to be quoted if it contains white space, everything after the first
non-white space character

For example:  (section headers)
[ section_one ]     #valid
[ section two ]     # not valid (no white space in name)
[section-three    ] # valid (white space discarded)
[ sectionfourislong]# valid


(key/value pairs) :
this = isvalid			# assign this => 'isvalid'
title = This is my title	# assign title => 'This is my title'



FOR DEVELOPERS:
  The methods supplied by Config are:
	new
	pathname
	mainvalue
	getsection
	value
	sections

new(<filename>)
  Called with the config file as an argument:
    $cfg = Mondo::Config->new("mondo.conf");
  (or whatever the name ends up being), returns an instance of the
configuration, look below for a sample dump.

pathname()
  Either sets or retrieves the current configfile.  Setting it after calling new
does no good, and you can't call it before you call new, so use it only for
retrieving the config file name.

mainvalue(<key>, <value>)
  Set or retrieve value from the main configuration area.  To set a value, 
call it with both the key you wish to set (doesn't have to exist already), 
and the value you wish to set it to.  If you want to retrieve a specific 
value call it without a value specified.  Always returns the current 
value (or value after setting it if you set a new value).

  print "Hostname is currently ".$cfg->mainvalue("hostname").".\n";
  print "But I'll change it to ".$cfg->mainvalue("hostname", "localhost").".\n";

getsection(<section_name>)
  Returns an assoc. array of the section passed.
  my %section = $cfg->getsection("sectionone");
  returns all of the key/value pairs contiained in "sectionone" of 
the config file.

value(<section>, <key>, <value>)
  works just as the mainvalue, except it needs to have a section passed 
also, to modify the key in that section.  Passing "main" does not work.  
Though it probably should in version 2.

sections()
  return an array of the section names.

  



$VAR1 = bless( {
            'signature' => 'whatever',
            'mailer' => '/usr/sbin/sendmail -t',
            'logfile' => '/dev/null',
            'mail' => 'jay@cake',
            'page' => 'hsijjj',
            'syslogid' => 'snap',
            'pathname' => 'snap.conf',
            'sysloglvl' => 'local5:info',
            'pager' => '/usr/local/bin/qpage',
            'debug' => 1
            'section' => {
                      'Netxmon' => {
                                'netxlookup' => '/usr/sys_watch/netx_lookup Z'
                                   },
                      'TestENQ' => {
                                'dest' => 'localhost',
                                'port' => 8100,
                                'timeout' => 5
                                   },
                      'Procerr' => {
                                'tlogdir' => '/usr/netx/data/tlog',
                                'grepfor' => 'PROCESSING ERROR',
                                'grep' => '/usr/bin/grep'
                                   },
                      'Ping' => {
                             'hosts' => 'dia1_rs6k,dia1_rtr,dia1_bct,dia2_rtr,uds1,uds2,uds3,uds4,bulky,ewing,wex-auth,pp1_rtr',
                             'timeout' => 5
                                },
                      'Rimwatch' => {
                                 'devcmd' => '/usr/netx/bin/netx_aware Z',
                                 'nstart' => '/usr/netx/bin/netx_obj_fnc Z start device',
                                 'nstop' => '/usr/netx/bin/netx_obj_fnc Z stop device',
                                 'savefile' => '/usr/jay/.rimwatch'
                                    },
                      'Diskspace' => {
                                  '/tmp' => '8%',
                                  '/usr/netx/data/log' => '6%',
                                  'defaultspace' => 20000,
                                  'ignore' => '/dev/cd0,/mnt,/dev/hd10',
                                  '/usr/eps/arc' => '4%',
                                  'uname' => '/usr/bin/uname -v',
                                  '/usr/netx' => '4%',
                                  '/var/tmp' => '6%',
                                  '/var' => '9%',
                                  '/home' => '8%',
                                  '/usr/sybase_11/tranlogs' => '12%',
                                  '/usr' => '5%',
                                  'df' => '/usr/bin/df',
                                  '/usr/rimstats' => '7%',
                                  '/' => '20%'
                                     }
                         },
          }, 'SNAP::Config' );

