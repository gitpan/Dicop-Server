

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Config</h1>

<!-- topic: DiCoP Config file format and documentation -->

<div class="text">

<p>
DiCoP Config file format and documentation
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#overview">OVERVIEW</a></li>
	<ul>

		<li><a href="#reading">Reading</a></li>
		<li><a href="#format">Format</a></li>
	</ul>

	<li><a href="#specific_files">SPECIFIC FILES</a></li>
	<ul>

		<li><a href="#server_cfg">server.cfg</a></li>
		<li><a href="#proxy_cfg">proxy.cfg</a></li>
		<li><a href="#client_cfg">client.cfg</a></li>
	</ul>

	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>This documentations covers the details of the configuration files for
<code>dicopd</code>, <a href="#item_server"><code>server</code></a> and <code>proxy</code> as well as the client.</p>

<p>Last update: 2004-12-20</p>

</div>



<h2><a name="overview">OVERVIEW</a></h2>

<div class="text">



</div>

<h3><a name="reading">Reading</a></h3>

<div class="text">

<p>The configuration files are only read at startup time. Changes to the files
do not have an effect until you restart the client/server process. This will
be fixed in the future.</p>

<p>The exception is <a href="#item_server"><code>server</code></a>, since it is restarted for each connect, it will
read the config file each time anew.</p>

<p>It is possible to view the config file for the server, but not yet to
edit the values. To edit the files, edit them with a text editor of your
choice.</p>



</div>

<h3><a name="format">Format</a></h3>

<div class="text">

<p>The file format is simple. The text file is read line by line, any empty
line (or lines containing only spaces) are skipped.</p>

<p>The <code>#</code> sign denotes a comment, any line that starts with zero or more spaces
followed by such a character is skipped.</p>

<p>Any other line is interpreted as an entry. Entries consist of a key name and 
a value, seperated by <code>=</code>.</p>

<p>The key name is case insensitive.</p>

<p>Values are case-sensitive and values containing other characters than
0..9, a..z, A-Z or ``_'', ``-'' or ``.'' must be quoted by using <code>&quot;</code> around the
value.</p>

<p>If a key appears more than one time, it will hold a list consisting of all
values.</p>

<p>Sample file:</p>

<pre>
        # This is a comment

        # Empty lines are ignored, too

                # even this is ignored

        # a sample key
        key = value

        # this works, too
        # key is now [&quot;value&quot;,&quot;other_value&quot;]
        Key = other_value

        # another more complicated entry
        name = &quot;foo bar Baz&quot;</pre>

<p>Certain keys have a boolean value. Below they are marked with <code>B</code>. In these
case 1 means on, and 0 means off. You can also give as value 'on', 'yes',
'no' or 'off'. These will be interpreted case-insensitive.</p>



</div>

<h2><a name="specific_files">SPECIFIC FILES</a></h2>

<div class="text">



</div>

<h3><a name="server_cfg">server.cfg</a></h3>

<div class="text">

<p>This lists all the valid key names in the <em>server</em> config file (server.cfg by
default) and their possible values.</p>

<dl>
<dt><strong><a name="item_allow_admin">allow_admin</a></strong><br />
</dt>
<dd>
Contains a list of IPs or nets that are allowed to administrate
the server. Any IP not listed here is denied the right to submit changes.
Please note that you do not need to list the admins in <a href="#item_allow_status">allow_status</a> nor
<a href="#item_allow_stats">allow_stats</a>, they automatically get these rights.
</dd>
<dd>

<p>The word <code>any</code> is equivalent to <code>0.0.0.0/0</code> and <code>none</code> to <code>0.0.0.0/32</code>.</p>

</dd>
<dd>

<p>Note that <a href="#item_deny_admin">deny_admin</a> is checked first, if an IP is denied, L&gt;allow_admin&gt;
will not be checked. In addition, the default is deny, e.g. if not explicitely
listed, the right to do something is denied. To deny specific IPs (like
spoofed or 'impossible' ones) use the <a href="#item_deny_admin">deny_admin</a> or similiar settings.</p>

</dd>
<dd>

<p>You should deploy a packetfilter or firewall in addition to these settings.</p>

</dd>
<dd>

<p>Some examples on how to specify the IPs:</p>

</dd>
<dd>
<pre>
 0.0.0.0/32             all IPs (usually only for allow_work and allow_stats,
                        otherwise a bad idea
 any                    same as 0.0.0.0/0
 1.2.3.4/32             IP 1.2.3.4 only
 1.2.3.4                the same as 1.2.3.4/32
 1.2.3.0/24             class c net 1.2.3.0
 1.2.0.0/16             class b net 1.2.0.0
 1.2.3.4,1.2.4.0/24     1.2.3.4 and 1.2.4.0</pre>
</dd>
<dd>

<p>Here is one example of how to grant admin rights to everyone in a subnet,
except the machine with the IP 10.0.0.2:</p>

</dd>
<dd>
<pre>
        allow_admin = &quot;10.0.0.0/24&quot;
        deny_admin  = &quot;10.0.0.2&quot;</pre>
</dd>



<dt><strong><a name="item_allow_stats">allow_stats</a></strong><br />
</dt>
<dd>
The listed IPs are allowed to view the client list and the per-client status
page on the server.
</dd>
<dd>

<p>Please see <a href="#item_allow_admin">allow_admin</a> for an in depth discussion of the access right
management.</p>

</dd>



<dt><strong><a name="item_allow_status">allow_status</a></strong><br />
</dt>
<dd>
The listed IPs are allowed to view the general status and info pages on the
server. Please see <a href="#item_allow_admin">allow_admin</a> for an in depth discussion of the access
right management.
</dd>



<dt><strong><a name="item_allow_work">allow_work</a></strong><br />
</dt>
<dd>
The listed IPs are allowed to work on the server. Please see <a href="#item_allow_admin">allow_admin</a>
for an in depth discussion of the access right management.
</dd>



<dt><strong><a name="item_debug_level">debug_level</a></strong><br />
</dt>
<dd>
Set the debug level. Default is 0, recommended is 1.
</dd>
<dd>

<p>Set to 1 to enable debug mode (cmd_status;type_debug).
Set to 2 to enable leak reports in <code>logs/leak.log</code>. Warning: this generates
LOTs of data!</p>

</dd>
<dd>

<p>To make debug_level = 2 really usefull, you need to compile Perl with:</p>

</dd>
<dd>
<pre>
        ./configure -Accflags=-DDEBUGGING &amp;&amp; make</pre>
</dd>



<dt><strong><a name="item_deny_admin">deny_admin</a></strong><br />
</dt>
<dd>
The listed IPs are <strong>forbidden</strong> to administrate the server.
</dd>
<dd>

<p>Please see <a href="#item_allow_admin">allow_admin</a> for an in depth discussion of the access right
management.</p>

</dd>



<dt><strong><a name="item_deny_stats">deny_stats</a></strong><br />
</dt>
<dd>
The listed IPs are <strong>forbidden</strong> to view the client list and the per-client
status pages.
</dd>
<dd>

<p>Please see <a href="#item_allow_admin">allow_admin</a> for an in depth discussion of the access right
management.</p>

</dd>



<dt><strong><a name="item_deny_status">deny_status</a></strong><br />
</dt>
<dd>
The listed IPs are <strong>forbidden</strong> to view the general status and info pages on
the server. Please see <a href="#item_allow_admin">allow_admin</a> for an in depth discussion of the access
right management.
</dd>



<dt><strong><a name="item_deny_work">deny_work</a></strong><br />
</dt>
<dd>
The listed IPs are <strong>forbidden</strong> to work on the server. Please see
<a href="#item_allow_admin">allow_admin</a> for an in depth discussion of the access right management.
</dd>



<dt><strong><a name="item_hand_out_work_b">hand_out_work B</a></strong><br />
</dt>
<dd>
If on, server will hand out work to the client's. If set to off, the server
will accept reports and present status pages, but never give out new chunks.
</dd>



<dt><strong><a name="item_maximum_request_time">maximum_request_time</a></strong><br />
</dt>
<dd>
How many seconds to spent at most for handling each request. Do not set to
high, or the server may be locked by a client request to long. But not to
low either, or it won't be able to complete some requests. 5 seconds is a
reasonable cap.
</dd>



<dt><strong><a name="item_max_requests">max_requests</a></strong><br />
</dt>
<dd>
Maximum number of requests one connect can contain, default is 128.
</dd>



<dt><strong><a name="item_self">self</a></strong><br />
</dt>
<dd>
Address of server that is embedded into each generated HTML page to create
clickable links.
</dd>



<dt><strong><a name="item_name">name</a></strong><br />
</dt>
<dd>
The name of the server, used for displaying it on the status page and for
tagging out-going emails.
</dd>



<dt><strong><a name="item_port">port</a></strong><br />
</dt>
<dd>
The port <code>dicopd</code> will listen on. This is ignored by the <a href="#item_server"><code>server</code></a> running
under Apache.
</dd>



<dt><strong><a name="item_group">group</a></strong><br />
</dt>
<dd>
The group <code>dicopd</code> will actually run under. Make sure the group exists.
</dd>



<dt><strong><a name="item_user">user</a></strong><br />
</dt>
<dd>
The user <code>dicopd</code> will actually run under. Make sure it exists.
</dd>



<dt><strong><a name="item_flush">flush</a></strong><br />
</dt>
<dd>
For <code>dicopd</code>. Wait so many minutes before flushing out your data to disk. See
also <em>Dicop.pod</em>, section ``Data Integrity''.
</dd>



<dt><strong><a name="item_default_style">default_style</a></strong><br />
</dt>
<dd>
Set to which style to use as default, f.i. <code>Sea</code> or <code>default</code>.
</dd>



<dt><strong><a name="item_file_server">file_server</a></strong><br />
</dt>
<dd>
Prefix to URLs for the client to retrieve new worker and target files. Usually
this is an Apache server at the same machine as the main server is on, and
serving the files directly from the <code>worker/</code> and <code>target/</code> directories. But
you also could use NFS or whatever you like, as long as LWP is able to
retrieve an file from this URL. Appended to this URL will be paths like
<code>worker/archname/workername</code> or <code>target/jobid.tgt</code>.
</dd>
<dd>

<p>You can give multiple <a href="#item_file_server"><code>file_server</code></a> statements by having more than one line:</p>

</dd>
<dd>
<pre>
        file_server = &quot;<a href="http://127.0.0.1:8080/&quot">http://127.0.0.1:8080/&quot</a>;
        file_server = &quot;<a href="ftp://127.0.0.1/&quot">ftp://127.0.0.1/&quot</a>;</pre>
</dd>
<dd>

<p>These will all given to the client, and the client chooses the best server
to download files from (or simple the one that is reachable first).</p>

</dd>



<dt><strong><a name="item_mail_server">mail_server</a></strong><br />
</dt>
<dd>
Name or IP address of a SMTP server accepting connections on port 25. Set to
'none' to disable the email feature (no emails will then be sent).
</dd>



<dt><strong><a name="item_mail_admin">mail_admin</a></strong><br />
</dt>
<dd>
This user/address will get a copy of all sent mails
</dd>



<dt><strong><a name="item_mail_from">mail_from</a></strong><br />
</dt>
<dd>
This is the email address which will appear in all From: fields in mails sent
by the server.
</dd>



<dt><strong><a name="item_mail_to">mail_to</a></strong><br />
</dt>
<dd>
This is the email address to which all mails from the server will be sent.
See also <a href="#item_mail_admin">mail_admin</a>.
</dd>



<dt><strong><a name="item_def_dir">def_dir</a></strong><br />
</dt>
<dd>
The directory where definition files are kept. These come with the distribution
and need not to be edited.
</dd>



<dt><strong><a name="item_log_dir">log_dir</a></strong><br />
</dt>
<dd>
The directory storing the server's log files.
</dd>



<dt><strong><a name="item_msg_dir">msg_dir</a></strong><br />
</dt>
<dd>
The directory containing the message file, e.g. the file that translates
message numbers (like 200) into clear text, human readable messages.

</dd>
<dd>
<pre>

=item tpl_dir</pre>
</dd>
<dd>

<p>The template directory.</p>

</dd>



<dt><strong><a name="item_data_dir">data_dir</a></strong><br />
</dt>
<dd>
The data directory, containing the state (or memory) of the server.
</dd>



<dt><strong><a name="item_worker_dir">worker_dir</a></strong><br />
</dt>
<dd>
In this directory the worker are stored. The server uses them to build a hash
per worker file and then sends this hash to the client for verification of the
worker at the client side.
</dd>
<dd>

<p>It is a good idea to have the fileserver simple to point to this directory
with a symbolic link, so that they never get out of sync.</p>

</dd>
<dd>

<p>Don't just set the file server's DOCROOT simple to point to the DiCoP server's
root directory, this would allow anyone to fetch any file from the server,
including the password hashes of the admins and clients!</p>

</dd>



<dt><strong><a name="item_target_dir">target_dir</a></strong><br />
</dt>
<dd>
The target files for (some of) the jobs. These are hashed (just like the
workers) and the hash is then sent to the client.
</dd>
<dd>

<p>It is a good idea to have the fileserver simple to point to this directory
with a symbolic link, so that they never get out of sync.</p>

</dd>
<dd>

<p>Don't just set the file server's DOCROOT simple to point to the DiCoP server's
root directory, this would allow anyone to fetch any file from the server,
including the password hashes of the admins and clients!</p>

</dd>



<dt><strong><a name="item_mailtxt_dir">mailtxt_dir</a></strong><br />
</dt>
<dd>
The mail texts are found inside this template dir, usually it is a subdirectory
of the template dir <code>tpl_dir</code>.
</dd>



<dt><strong><a name="item_error_log">error_log</a></strong><br />
</dt>
<dd>
Name of the error log file, which will be located inside <a href="#item_log_dir"><code>log_dir</code></a>.
</dd>



<dt><strong><a name="item_server_log">server_log</a></strong><br />
</dt>
<dd>
Name of the server general log file, which will be located inside
<a href="#item_log_dir"><code>log_dir</code></a>.
</dd>



<dt><strong><a name="item_jobs_list">jobs_list</a></strong><br />
</dt>
<dt><strong><a name="item_clients_list">clients_list</a></strong><br />
</dt>
<dt><strong><a name="item_groups_list">groups_list</a></strong><br />
</dt>
<dt><strong><a name="item_charsets_list">charsets_list</a></strong><br />
</dt>
<dt><strong><a name="item_jobtypes_list">jobtypes_list</a></strong><br />
</dt>
<dt><strong><a name="item_proxies_list">proxies_list</a></strong><br />
</dt>
<dt><strong><a name="item_results_list">results_list</a></strong><br />
</dt>
<dt><strong><a name="item_testcases_list">testcases_list</a></strong><br />
</dt>
<dt><strong><a name="item_patterns_file">patterns_file</a></strong><br />
</dt>
<dt><strong><a name="item_objects_def_file">objects_def_file</a></strong><br />
</dt>
<dt><strong><a name="item_log_level">log_level</a></strong><br />
</dt>
<dd>
Specify the logging level.
</dd>
<dd>

<p>These values are cumulative, meaning adding them together will yield what
is logged. Default is 7. A log_level above 4 will generate LOTs of data!
You can also write it like log_level = 1+2+16</p>

</dd>
<dd>
<pre>
        0 - no loggging
        1 - log critical errors
        2 - log important server messages (startup/shutdown)
        4 - log non-critical errors
        8 - log unimportant server messages (data flush etc)</pre>
</dd>
<dd>
<pre>
        Warning, the next two settings generate a lot of output!</pre>
</dd>
<dd>
<pre>
        16 - log all requests
        32 - log all responses</pre>
</dd>



<dt><strong><a name="item_minimum_rank_percent">minimum_rank_percent</a></strong><br />
</dt>
<dd>
Job with minimum rank gets this percent of all chunks (f.i. 90%), all the rest
of the runnnig job share the rest of the cluster load (f.i. 10%).
</dd>



<dt><strong><a name="item_minimum_chunk_size">minimum_chunk_size</a></strong><br />
</dt>
<dd>
In minutes. Client's requests for chunks less than this time will get
increased to this time.
</dd>



<dt><strong><a name="item_maximum_chunk_size">maximum_chunk_size</a></strong><br />
</dt>
<dd>
In minutes. Client's requests for chunks more than this time will get
decreased to this time.
</dd>



<dt><strong><a name="item_resend_test">resend_test</a></strong><br />
</dt>
<dd>
Time in minutes after which a testcase is resend to a client that failed too
often. Default is 6 hours.
</dd>



<dt><strong><a name="item_require_client_version">require_client_version</a></strong><br />
</dt>
<dd>
Clients with a lower version than this are not allowed to connect. Set to 0
to disable this check.
</dd>



<dt><strong><a name="item_require_client_build">require_client_build</a></strong><br />
</dt>
<dd>
Clients with a build number lower than this are not allowed to connect, unless
their version is higher than <a href="#item_require_client_version"><code>require_client_version</code></a>. Is not checked when
<a href="#item_require_client_version"><code>require_client_version</code></a> is set to 0.
</dd>



<dt><strong><a name="item_client_architectures">client_architectures</a></strong><br />
</dt>
<dd>
Allowed client architecture names, anything else is invalid.
</dd>



<dt><strong><a name="item_client_check_time">client_check_time</a></strong><br />
</dt>
<dd>
Time in hours between two checks. When more than this time has passed, the
server performs a check for each of it's clients to see whether they were
not sending in reports for at least <a href="#item_client_offline_time">client_offline_time</a> hours. Set to 0 to
disable this check.
</dd>
<dd>

<p>When a client goes from online to offline status, an email is sent to the
administrator.</p>

</dd>



<dt><strong><a name="item_client_offline_time">client_offline_time</a></strong><br />
</dt>
<dd>
Time in hours that a client is permitted to not return results before it is
reported as missing. For each client that goes offline one email is sent, once.
See also <a href="#item_client_check_time">client_check_time</a>.
</dd>



<dt><strong><a name="item_charset_definitions">charset_definitions</a></strong><br />
</dt>
<dd>
Filename (usually in <code>worker/</code> so that these can find it) for the character
set definitions use by the worker files. Created (overwritten) upon startup 
and automatically regenerated whenever a charset is added/deleted/changed.
</dd>



<dt><strong><a name="item_initial_sleep">initial_sleep</a></strong><br />
</dt>
<dd>
Time in seconds to wait before changing user and group and starting to work.
Default is 0.
</dd>

</dl>



</div>

<h3><a name="proxy_cfg">proxy.cfg</a></h3>

<div class="text">

<p>This lists all the valid key names in the <em>proxy</em> config file (proxy.cfg by
default) and their possible values.</p>

<p>Any key in proxy.cfg will override the <code>key(s)</code> in server.cfg! If you list
multiple keys, they will be keept as list, as usual. So:</p>

<pre>
        # server.cfg

        foo = blah
        # foo now ['blah','bar']
        foo = bar

        name = bazzle

        # proxy.cfg

        # foo is now 'buh'!
        foo = buh
        # foo is now ['buh','huh']
        foo = huh
        # name is still bazzle</pre>
<dl>
<dt><strong><a name="item_upstream_server">upstream_server</a></strong><br />
</dt>
<dd>
Name of the main server the proxy talks to (aka the server the proxy is doing
the caching for).
</dd>



<dt><strong>error_log</strong><br />
</dt>
<dd>
The name of the error log file. This overrides the value set in <code>server.cfg</code>.
</dd>

</dl>



</div>

<h3><a name="client_cfg">client.cfg</a></h3>

<div class="text">

<p>This lists all the valid key names in the <em>client</em> config file (client.cfg by
default) and their possible values.</p>

<dl>
<dt><strong><a name="item_sub_arch">sub_arch</a></strong><br />
</dt>
<dd>
The sub-architecture string that will be appended to the architecture name.
Example:
</dd>
<dd>
<pre>
        sub_arch        = &quot;i386&quot;</pre>
</dd>
<dd>

<p>This can be used to distinguish clients with the same operating system,
but different arcitectures (like different CPU, OS version) from each
other. You can also use it to differentiate between client groups like
this:</p>

</dd>
<dd>

<p>In one config:</p>

</dd>
<dd>
<pre>
        sub_arch        = &quot;i386-office&quot;</pre>
</dd>
<dd>

<p>And for some other clients:</p>

</dd>
<dd>
<pre>
        sub_arch        = &quot;i386-offsite&quot;</pre>
</dd>
<dd>

<p>If the proper subdirectories exist at the server side, this will serve
different worker files to the clients.</p>

</dd>



<dt><strong><a name="item_id">id</a></strong><br />
</dt>
<dd>
The id number of the client. This is assigned by the server administrator. 
The default is 0. The value can (in case of 0 must) be overwritten on the
commandline with <code>--id=number</code>.
</dd>



<dt><strong><a name="item_server">server</a></strong><br />
</dt>
<dd>
All keys with the name server list server addresses the client is going to use.
There is no difference between a server or a proxy, from the client's point of
view they are the same.
</dd>
<dd>

<p>The format is either with or without the leading <code>http://</code>:</p>

</dd>
<dd>
<pre>
        server = <a href="http://127.0.0.1:8088/cgi-bin/dicop/server">http://127.0.0.1:8088/cgi-bin/dicop/server</a>
        server = 192.168.1.2:8888</pre>
</dd>
<dd>

<p>In case of dicopd servers the path does not matter.</p>

</dd>



<dt><strong><a name="item_random_server">random_server</a></strong><br />
</dt>
<dd>
If set to 0, all servers listed under <a href="#item_server">server</a> will tried in turn.
If set to 1, servers are tried randomly.
</dd>



<dt><strong><a name="item_chunk_size">chunk_size</a></strong><br />
</dt>
<dd>
Prefered chunk size in minutes, ranging from 1 to 360. The value should be
between 20 (for interactive workstations) to 50 (for unattended cluster nodes).
</dd>



<dt><strong><a name="item_update_files">update_files</a></strong><br />
</dt>
<dd>
If set to 0, missing workers and target fules will <strong>not</strong> be automatically
downloaded. Set to 1 to allow download and update of missing/outdated files.
</dd>
<dd>

<p>If you have your client in a directory mounted over NFS, it is a good idea to
have the worker and target dir local (disk or ramdisk) and allow updating.
Otherwise, the clients would fight over who should/could download a worker and
store it in the shared directory.</p>

</dd>
<dd>

<p>There is a problem with target files. The best solution is to store them
directly in the directory the client uses as target (maybe point the
<a href="#item_target_dir">target_dir</a>) directly to the directory the server uses as target dir. This
way the client finds the workers and targets and doesn't need to retrieve them.</p>

</dd>



<dt><strong>log_dir</strong><br />
</dt>
<dd>
The directory storing the client's log files.
</dd>



<dt><strong><a name="item_cache_dir">cache_dir</a></strong><br />
</dt>
<dd>
Certain files are chached here, mainly scratch files when using the wget
connector method.
</dd>



<dt><strong>worker_dir</strong><br />
</dt>
<dd>
Inside this directory the worker files are stored.
</dd>



<dt><strong>msg_dir</strong><br />
</dt>
<dt><strong>error_log</strong><br />
</dt>
<dd>
Name of the error log file. Default is ``client_##id##.log''.
</dd>



<dt><strong><a name="item_wait_on_error">wait_on_error</a></strong><br />
</dt>
<dd>
How many seconds to wait when an error occurs. Don't set to low, otherwise
the server will slow down the client.
</dd>



<dt><strong><a name="item_wait_on_idle">wait_on_idle</a></strong><br />
</dt>
<dd>
How many seconds to wait when no work is available from the server. Don't set
to low, otherwise the server will slow down the client.
</dd>



<dt><strong><a name="item_via">via</a></strong><br />
</dt>
<dd>
Name of the connector used to talk to the server. Examples:
</dd>
<dd>
<pre>
        via = &quot;wget&quot;
        via = &quot;LWP&quot;</pre>
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


