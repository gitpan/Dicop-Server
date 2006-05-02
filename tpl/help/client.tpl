

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Client</h1>

<!-- topic: This covers the DiCoP client from the end-user's point of view. -->

<div class="text">

<p>
This covers the DiCoP client from the end-user's point of view.
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#options">OPTIONS</a></li>
	<li><a href="#client_install">CLIENT INSTALL</a></li>
	<ul>

		<li><a href="#full_install">Full install</a></li>
		<li><a href="#automated_download">Automated download</a></li>
		<li><a href="#client_prerequisites">Client prerequisites</a></li>
		<li><a href="#mounting_over_nfs_or_samba">Mounting over NFS or Samba</a></li>
	</ul>

	<li><a href="#data_transmitted_to_from_server">DATA TRANSMITTED TO/FROM SERVER</a></li>
	<ul>

		<li><a href="#sending">SENDING</a></li>
	</ul>

	<li><a href="#downloading">DOWNLOADING</a></li>
	<li><a href="#smp_machines__hyperthreading">SMP MACHINES, HYPERTHREADING</a></li>
	<li><a href="#troubleshooting">TROUBLESHOOTING</a></li>
	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>Last update: 2004-12-22</p>

</div>



<h2><a name="options">OPTIONS</a></h2>

<div class="text">

<p>When starting the client, you can use the following command line options:</p>

<pre>
        id              optional client id. If unspecified, read from the
                        config file.
        config          name of the config file to use. Defaults to
                        &quot;config/client.cfg&quot;
        language        Default is 'en'
        debug           Output debug information. The higher the level, the
                        more information is printed
        test            default: Request and work upon testcases
                        Use --notest to disable, this is usefull in
                        combination with --chunks=1
        chunks          Work only on so much chunks, then exit. 0 is default
                        and disables it. Testcases do count!
        chunk_count     Cache so many chunks and work on them in a row,
                        Default is 1
        retries         Upon failure to connect to server, retry so many times
                        before giving up and exiting. Defaults to 16
        server          Instead of reading the server lines from a config
                        file, use this server
        arch            Architecture (linux, armv4l, os2, mswin32 etc)
                        Usually not neccessary, since autodetected
        sub_arch        Sub-architecture string, will be appended to arch.
                        Examples: 'i386', 'i386-amd'. Can be any lowercase
                        string containing letters, numbers. minus and
                        underscore. '-' is used to seperate further sub archs.
        via             The connector method, default is &quot;LWP&quot;. Also possible
                        is &quot;wget&quot;. Additionally parameters are added with a
                        ',', see examples below
        user            the user name the process should use after starting
                        (f.i. dicop, nobody etc)
        group           the group name the process should use after starting
                        (f.i. dicop, nogroup etc)
        chroot          the directory were to chroot() after starting. Does
                        currently not work and is thus disabled (set to &quot;&quot;).</pre>

<p>To use the <code>chroot()</code> setting, you must start the client as root. It is
recommended that you always use the <code>user</code> and <code>group</code> settings together
with the <code>chroot</code> setting. Under Win32, these settings might not work.</p>

<p>Here are some examples:</p>

<pre>
        perl client --id=31337 --language=en --config=config/myconf.cfg
        perl client --server=<a href="http://127.0.01/cgi-bin/dicop/server">http://127.0.01/cgi-bin/dicop/server</a>
        perl client --server=127.0.01:8888
        perl client --notest --chunks=1 --debug=3
        perl client --notest --arch=armv4l --id=1234
        perl client --arch=armv4l --id=1 --via=wget
        perl client --arch=armv4l --id=1 --via=wget,proxy=OFF
        perl client --retries=32 --chunk_count=24 --id=123
        perl client --arch=linux --sub_arch=i386 --id=1</pre>

<p>You may abbreviate the options as long as they are distingushable from each
other:</p>

<pre>
        ./client --id=123 --lang=de --deb=2
        ./client --d=1</pre>

<p>You can stop the client at any time, by just aborting it, or killing the
process. Pressing CTRL-C also works just fine.</p>

<p>If you are just a mere user of the client, there is no need to read further.</p>



</div>

<h2><a name="client_install">CLIENT INSTALL</a></h2>

<div class="text">

<p>This covers the installation of the client, which should be done by the
administrator or someone with experience in these matters.</p>



</div>

<h3><a name="full_install">Full install</a></h3>

<div class="text">

<p>You can either download the complete client package, untar/unzip it or
mount it via <a href="#mounting_over_nfs_or_smb">net</a> from the server (for diskless
workstations etc).</p>

<p>In the first case, you should specify the client ID in the config file to
avoid having to retype it.</p>

<p>To start the client, change to the client dirrectory and run <code>perl client</code>.</p>



</div>

<h3><a name="automated_download">Automated download</a></h3>

<div class="text">

<p>This is the recommended setup for a client.</p>

<p>The following perl script will connect to a HTTP server, download the
client, unpack it, and then run it. The client should be available at the
given address and the included configuration file should allow automated
download of workers and target files. Thus you can setup a diskless machine
(or booting one from a CD-ROM) to download the latest client version and run
it. The missing worker files will be pulled down automatically.</p>

<p>This script assumes that the client's ID is the same as the last octet of his
IP address. When used in conjunction with a DHCP server, all you need is to
add the clients to the DiCoP (w/ proper ID and IP) and DHCP (w/ proper MAC
and IP) server, and then turn them on.</p>

<p>Adjust the IPs in the script, or use hostnames in conjunction with a
nameserver:</p>

<pre>
        #!/usr/bin/perl -w

        use strict;                             # strict perl code

        # create dir and chdir there
        mkdir '/tmp/client', 0700;              # old Perl needs mask
        chdir '/tmp/client';

        # get my own ip via ifconfig
        # you also could use uname -n or something similiar
        my $rc = `ifconfig`;
        $rc =~ /inet addr:\s*(\d+)\.(\d+)\.(\d+)\.(\d+)/;

        # Calculate the client ID from the client IP. This trick
        # allows us to bind each machine name with a specific ID
        # without having it to pass to that machine. It is assumed
        # that a DHCP server always hands the same machine the same
        # IP to simplify things.

        my $ip = &quot;$1.$2.$3.$4&quot;;
        my $net = sprintf(&quot;%03i&quot;,$3);
        my $id = $net . sprintf(&quot;%03i&quot;,$4);
        print &quot;ip $ip net $net id $id\n&quot;; sleep(2);

        # endless loop:
        while (3 &lt; 5)
          {
          # remove old version first (if it exists)
          unlink 'latest-client.tar.gz';

          # get newest client with wget via HTTP
          # change the IP to your fileservers address
          `wget -U DiCoP -c <a href="http://dicop-server/latest-client.tar.gz">http://dicop-server/latest-client.tar.gz</a>`;

          # unpack it
          `tar -xzf client.tar.gz`;

          # the following command will only terminate if something
          # went wrong, like the server told the client to terminate
          # or the client became outdated:
          system &quot;perl client --id=$id --server=dicop-server:8888&quot;;

          print (&quot;Something went wrong, trying again in 300 seconds.\n&quot;);
          print (&quot;Press CTRL-C to abort.\n&quot;;

          # wait a bit, otherwise we could overload the server(s)
          sleep(300);
          }</pre>

<p>The system you run this on needs wget, and all the modules the client needs.</p>

<p>However, you can also include any modules (except Digest::MD5 and libwww) in
the latest-client.tar.gz file (under lib/), so that the machine always uses the
latest (or working) version, regardless of what it has locally installed. See
below:</p>



</div>

<h3><a name="client_prerequisites">Client prerequisites</a></h3>

<div class="text">

<p>Here is an example: Under ./lib of the client bundle, we put in Math::BigInt,
so that the client will carry it's own version. This means the client will always
use the version supplied in the bundle, not the one locally install on the node.
Thus updating Math::BigInt on all nodes is not necc., you can just include a newer
version into the client bundle and the next time the client get's updated, it will
pick up the new version.</p>

<p>Before:</p>

<pre>
        lib/Dicop.pm
        lib/Dicop/Client.pm
        ...</pre>

<p>And after:</p>

<pre>
        lib/Dicop.pm
        lib/Dicop/Client.pm
        lib/Math/BigInt.pm
        lib/Math/BigFloat.pm
        lib/Math/BigInt/Calc.pm
        ...</pre>

<p>You generally only need to copy the files from the ./lib dir from any distribution
you want to include into the client dir. This does, however, only work for modules
that are not required to be compiled (e.g. using XS/C code like Digest::MD5) or
autosplit. Most pure perl modules are ok, this includes Math::BigInt, Math::String
and Linux::Cpuinfo.</p>

<p>If Linux::Cpuinfo is not available, the client will work without it.</p>

<p>The client needs quite a few parts of <code>Dicop::Base</code>. However, we seperated the
things so that you can simple drop a few of the <code>Dicop::Base</code> .pm files into
the client dir, and have it work without making it necc. to install
<code>Mail::Sendmail</code>, <code>Net::Server</code> etc at the node.</p>

<p>Here is a short list of files the client needs at least:</p>

<pre>
        lib/basics
        lib/Dicop.pm
        lib/Dicop/Base.pm
        lib/Dicop/Cache.pm
        lib/Dicop/Client.pm
        lib/Dicop/Config.pm
        lib/Dicop/Connect.pm
        lib/Dicop/Event.pm
        lib/Dicop/Hash.pm
        lib/Dicop/Item.pm
        lib/Dicop/Request.pm

        lib/Dicop/Client/LWP.pm
        lib/Dicop/Client/wget.pm

        lib/Dicop/Request/Pattern.pm</pre>

<p>This one is optional:</p>

<pre>
        lib/Linux/Cpuinfo.pm</pre>

<p>The other solution is to install Dicop::Base and all it's prerequisites
at every node.</p>

<p>To make it easier to deploy clients we publish a <code>Dicop-Client-3.00.tar.gz</code>
package at our website, which contains everything the client needs, except
<code>libwww</code> and <code>Linux::Cpuinfo</code>, which can be found on <a href="http://search.cpan.org">http://search.cpan.org</a>.</p>



</div>

<h3><a name="mounting_over_nfs_or_samba">Mounting over NFS or Samba</a></h3>

<div class="text">

<p>You can mount the client dir via NFS/SMB (Samba). To achieve this, create
the following structure locally (better inside a sub dir to avoid cluttering
up root):</p>

<pre>
        /client
        /logs
        /worker
        /target
        /cache</pre>

<p><code>target</code>, <code>worker</code>, <code>cache</code> and <code>logs</code> should be writable. You can specify
these directories inside the <strong>client.cfg</strong> file and they default to
<em>``../name''</em>. Thus <code>client/../worker</code> refers to the worker dir above and
all turns out as expected for the client.</p>

<p>All clients will log to different log files, so you need only one central log
directory. However, <code>target</code> and <code>worker</code> should be an extra directory for
each client, to avoid that multiple clients write over each others files.</p>

<p>If you want to gather all the client's error logs, you could mount <code>logs</code> as
one dir on a separate machine or at the server machine.</p>

<p>Mount <code>client</code> as read-only directly to the servers directory (aka 'client',
'server' etc should exist in this directory). If you do not want to give
the workstations access to all the server's data, you can do two things:</p>

<dl>
<dt><strong><a name="item_links">links</a></strong><br />
</dt>
<dd>
You can move the files/data the client needs to another directory, and let
the client mount this dir. The server may need links to this so that it can
also access the same data/files (for updating it etc).
</dd>
<dd>

<p>Advantage is that a new server version also updates the client.</p>

</dd>



<dt><strong><a name="item_copying">copying</a></strong><br />
</dt>
<dd>
Just copy over any files the client needs to a separate dir and let the
client mount it.
</dd>
<dd>

<p>The disadvantage is that you need to manually update the client by copying over
a new server version. This happens only for changes to the client/server source
code, though, not the actual workers - these are downloaded by the client
automatically.</p>

</dd>

</dl>

<p>In both cases the client needs the following directory structure:</p>

<pre>
        client          - the client itself
        /lib            - libraries and code
        /msg            - messages
        /config         - only /config/client.cfg
        /cache          - for --via=wget to store temp. files
        /worker         - to store worker files
        /target         - to store targets, dictionaries etc</pre>



</div>

<h2><a name="data_transmitted_to_from_server">DATA TRANSMITTED TO/FROM SERVER</a></h2>

<div class="text">



</div>

<h3><a name="sending">SENDING</a></h3>

<div class="text">

<p>The client will transmit the following information to the server:</p>

<ul>
<li>Architecture and sub architecture



<li>Operating system name and version



<li>Client version



<li>Fan speed and CPU temparature



<li>It's process ID.



<li>It's unique ID and, optionally, a secret token for authentication.



<li>The results of the work the client did and how long it took.

</ul>

<p>The information goes unencrypted over the network. For additionally security
the server is able to check the IP address of the client. This can not work
for dynamic IP's, of course. A challenge-response handshake is planned,
but not yet realized.</p>

<p>If you want to secure the communication between server and client, use an
encrypted tunnel like <code>stunnel</code> or <code>IP-Sec</code>.</p>



</div>

<h2><a name="downloading">DOWNLOADING</a></h2>

<div class="text">

<p>From time to time the client may download a new worker or target file. A
worker is the program which get's called by the client to work on a certain
job. The target files are target information for a job and used when the
normal target information is too big to be passed over the command line.</p>

<p>These downloads will happen automatically, but only when there is need for
a new worker or target file. You can disable the downloads in the config file
by setting <code>update_file</code> to 0. However, this might prevent the client from
working properly.</p>



</div>

<h2><a name="smp_machines__hyperthreading">SMP MACHINES, HYPERTHREADING</a></h2>

<div class="text">

<p>The client and worker only takes advantages of one physical CPU. If you have
a machine with two (or more) physical or virtual (hyperthreading) CPU cores,
you can simple start two or more clients on the same machine.</p>

<p>These will each start a worker on their own, and each of these workers will
be using one CPU core. Of course, you need a good OS that keeps each process
on one CPU instead of switching them around.</p>

<p>Starting two clients on a machine with only one CPU will probably de-
instead of increasing performance.</p>



</div>

<h2><a name="troubleshooting">TROUBLESHOOTING</a></h2>

<div class="text">

<p>When you get error messages, don't panic!</p>

<p>First, you can try <code>--debug=nr</code> and replace <code>nr</code> by 1,2 or 3 to get more
information on what is going on. Here are a couple of messages and their
meanings:</p>

<dl>
<dt><strong><a name="item__22301_wait_2c_currently_no_work_for_you_22">``301 Wait, currently no work for you''</a></strong><br />
</dt>
<dd>
The server currently has not work for your client. The client will retry again
later automatically. Any message starting with 30x will denote that your
client has to make a break.
</dd>
<dd>

<p>Sometimes this happens because the client talked too often and too fast to
the server, and sometimes there is just no running job at the server.</p>

</dd>



<dt><strong><a name="item__22400_unknown_or_invalid_client__27id_27_22">``400 Unknown or invalid client 'id'''</a></strong><br />
</dt>
<dd>
The id your client is using is unknown to the server. Either specifiy the
correct id with <code>--id=number</code> (replace number with the actual id), or if you
don't have an ID yet, talk to the server administrator to get an ID.
</dd>
<dd>

<p>If you are the administrator, create a new client by connecting to the
server's web interface and use ``Add client'' from the menu.</p>

</dd>



<dt><strong><a name="item__22601_illegal_client_id_0_2e_please_specify_with_">``601 Illegal client id 0. Please specify with --id=id_number''</a></strong><br />
</dt>
<dd>
Please see <a href="#400_unknown_or_invalid_client__id_">400 Unknown or invalid client 'id'</a>.
</dd>



<dt><strong><a name="item__22604_could_not_run_worker__27name_27_22">``604 Could not run worker 'name'''</a></strong><br />
</dt>
<dd>
The client did not find the worker, did not have permission or something else
went wrong. Try to start the client with <code>--debug=3</code> for additional details.
</dd>

</dl>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.</p>



</div>


