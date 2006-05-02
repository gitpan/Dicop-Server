

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - New</h1>

<!-- topic: What's new -->

<div class="text">

<p>
What's new
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#changes_in_v3_00">CHANGES in v3.00</a></li>
	<li><a href="#refactored_code">REFACTORED CODE</a></li>
	<li><a href="#design_changes">DESIGN CHANGES</a></li>
	<li><a href="#web_interface__gui_">WEB INTERFACE (GUI)</a></li>
	<li><a href="#bug_fixes">BUG FIXES</a></li>
	<ul>

		<li><a href="#improved_security">Improved security</a></li>
	</ul>

	<li><a href="#new_features">NEW FEATURES</a></li>
	<li><a href="#known_issues">KNOWN ISSUES</a></li>
	<li><a href="#caveats">CAVEATS</a></li>
	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>




<h2><a name="changes_in_v3_00">CHANGES in v3.00</a></h2>

<div class="text">

<p>This document details the changes between the last and the current version.</p>



</div>

<h2><a name="refactored_code">REFACTORED CODE</a></h2>

<div class="text">

<p>Although on the outside, v3.00 looks almost exactly like v2.23, this release
is quite different under the hood. The code was split into generic and DiCoP
specific parts and all the generic parts were moved to the package
Dicop-Base. This allows us to reuse the generic parts for other projects.</p>

<p>Here are some of the under-the-hood changes that make life for us (the
developers) easier, but shouldn't affect you directly:</p>

<dl>
<dt><strong><a name="item_request_patterns">Request patterns</a></strong><br />
</dt>
<dd>
The requests (the messages exchanged between client or browser and the
server) are no longer hardcoded into the source. Instead a text file
<code>def/request.def</code> defines now the allowed requests with their parameters
and options. There should be no need to edit this file, though.
</dd>



<dt><strong><a name="item_object_patterns">Object patterns</a></strong><br />
</dt>
<dd>
Likewise, the internal server objects (like jobs, testcases and so on) are
now defined in <code>def/objects.def</code>. There should be no need to edit this file,
either.
</dd>



<dt><strong><a name="item_better_template_system">Better template system</a></strong><br />
</dt>
<dd>
Edit and add forms are now generated via a general <code>edit_object.tpl</code>
respectively <code>add_object.tpl</code> template, which automatically includes the
relevant edit fields from small include files called <code>editfield_FOO.inc</code>.
This makes maintaining and/or changing them much easier and prevents mistakes
from Copy&amp;Paste.
</dd>

</dl>

<p>Here is a list of some of the changes that might affect you:</p>



</div>

<h2><a name="design_changes">DESIGN CHANGES</a></h2>

<div class="text">
<dl>
<dt><strong><a name="item_test_3a_3asimple_v0_2e47_and_perl_v5_2e8_2e3_requi">Test::Simple v0.47 and Perl v5.8.3 requirements</a></strong><br />
</dt>
<dd>
We started to move over the testsuite to Test::Simple - this means this module
is now required to run the testsuite. However, since Dicop::Server now needs
at least Perl v5.8.3 to run, you will likely already have the required
Test::Simple module.
</dd>



<dt><strong><a name="item_sll">IO::Socket::SLL (and OpenSSL and Net::SSLeay) requirements</a></strong><br />
</dt>
<dd>
If you plan to use the new SSL feature of the server, or client, then these
modules must be installed.
</dd>



<dt><strong><a name="item_the_client_requirements">The client requirements</a></strong><br />
</dt>
<dd>
The client needs quite a few parts of Dicop::Base. However, we seperated the
things so that you can simple drop a few of the Dicop::Base .pm files into
the client dir, and have it work without making it nec. to install
Mail::Sendmail, Net::Server etc at the node.
</dd>
<dd>

<p>Here is a short list of files the client needs:</p>

</dd>
<dd>
<pre>
        lib/basics
        lib/Dicop.pm
        lib/Dicop/Base.pm
        lib/Dicop/Cache.pm
        lib/Dicop/Client.pm
        lib/Dicop/Config.pm
        lib/Dicop/Event.pm
        lib/Dicop/Hash.pm
        lib/Dicop/Item.pm
        lib/Dicop/Request.pm</pre>
</dd>
<dd>
<pre>
        lib/Dicop/Client/LWP.pm
        lib/Dicop/Client/wget.pm</pre>
</dd>
<dd>
<pre>
        lib/Dicop/Request/Pattern.pm</pre>
</dd>
<dd>
<pre>
        lib/Linux/Cpuinfo.pm</pre>
</dd>
<dd>

<p>The other solution is to install Dicop::Base and all it's prerequisites
at every node.</p>

</dd>
<dd>

<p>To make it easier to deploy clients we publish a Dicop-Client-3.00.tar.gz
package at our website, which contains everything the client needs, except
<code>libwww</code> and <code>Linux::Cpuinfo</code>, which can be found on <a href="http://search.cpan.org">http://search.cpan.org</a>.</p>

</dd>

</dl>



</div>

<h2><a name="web_interface__gui_">WEB INTERFACE (GUI)</a></h2>

<div class="text">

<p>The web-frontend (e.g the GUI you see when you connect to the server with
a browser) has got many small fixes and enhancements. This includes:</p>

<ul>
<li>graphical percentage bars instead of just plain text



<li>mouse-over titles for many links and texts that give you more information
without clicking or burdening the view with lots of (usually not needed) text



<li>menus in the upper-right corner for Help/Edit/Delete etc instead of hard
to find text-links buried in the middle of the page



<li>'Browse' buttons allow you to select files/directories from a list of
existing files instead of manually typing their path and name into an
edit field



<li>all edit and add forms are now automatically puzzled together from templates
for each valid field of the object, instead of generated from a single
template file per object type. This allows much easier adjusting of these
formulars and makes a lot of improvements like grouping (both by indending
and coloring) possible.

</ul>



</div>

<h2><a name="bug_fixes">BUG FIXES</a></h2>

<div class="text">

<p>Here is a listing of important bugs that have been fixed, testcases were
added to prevent these from happening again:</p>

<ul>
<li>Embedding the timestamp in the mail-templates results now in a readable
time, instead of just the seconds since 1970. Not everybody might be able
to do the conversion in his head ;)



<li>Editing the <code>minlen</code> of a Jobtype is now possible.



<li>Editing the settings of a proxy is now again possible.



<li>It is now possible to give a file as a target for a testcase (as it always
was possible for normal jobs), and if there was a script associated with the
testcase's jobtype, then this script will be run and generate a <code>.tgt</code> file
for the testcase.



<li>Setting a field of an object to the empty string was not possible since all
empty browser params were filtered away.

<p>Formerly this wasn't actually necessary, but now cases can have empty URL
fields.</p>



<li>Errors in a config file now cause the server to actually report a
proper warning including filename and line number where they are encountered.



<li>Obsolete keys in the config are now detected, and produce an error upon startup.



<li>The client now first gathers all filenames it needs to do it's work, then
checks which ones are missing/outdated and then asks the server in one connect
to get the download locations of the missing/outdated files. It then downloads
them one by one, as usual.

<p>This solves the problem that fresh clients that need to download a lot of
workers (f.i. just to work on the testcases) caused a lot of connects to the
server to ask for the download locations of the files. And with lots of
connects in a short time frame the client could hit the <strong>rate-limit</strong> even
before it did any real work, since requests for filenames count towards that
limit.</p>

<p>This also reduces the number of connects to the server, and hence it's load.</p>



<li>When adding simple charsets, multiple sequences are now handled correctly. This
means that you can enter things like <code>'a'..'z', '0'..'9'</code> and it will work
as expected. Formerly only one sequence was allowed, contradicting what the
help said.



<li>Checking other jobs with a found result did not work properly, and the check
list (e.g. the list containing the results from other jobs with the same
charset) did not survive a shutdown/restart cycle of the server.



<li>The server now handles requests for ``favicon.ico'' much more gracefully, e.g.
it ignores them. Formerly, newer browsers like Firefox would request the
icon with each request, and the server always generated the main status page
instead. This caused longer delays and wasted CPU time for browsing the HTML
interface.

</ul>



</div>

<h3><a name="improved_security">Improved security</a></h3>

<div class="text">
<ul>
<li>The server now checks the IP address of the connecting client/proxy against
the stored address and mask. Please make sure that your server contains the
proper IP info, otherwise client connects will be denied!



<li>The client now has the ability to support SSL connections to both the
server/proxy and/or the fileserver. Use <code>https://dicop-server:8888/</code>
will automatically encrypt the connection with SSL if both the necessary
modules are installed at the client, and the server/proxy supports
SSl (config has <code>proto = &quot;SSL&quot;</code> at the server/proxy side, see below).



<li>Server, proxy and client now have the ability to support the SSL protocol via
the <code>proto = &quot;ssl&quot;</code> setting in the config file. Together with updated clients
this allows all communication between server and client to be encrypted.

<p>However, at the moment the server can only be either <code>ssl</code> or <code>tcp</code>,
as indicated by the <code>proto = &quot;foo&quot;</code> setting in the config, e.g. you cannot
mix SSL and non-SSL clients (this is a limitation of <code>Net::Server</code>, and
currently there is no way to overcome this without rewriting a lot of
third-party code from scratch).</p>

<p>This means that if you switch a server to SSL, <strong>all</strong> clients must also
connecting to that server must also support SSL.</p>

<p>To overcome this limitation, use your server with <code>proto = &quot;tcp&quot;</code> and then
add a proxy to it. Run then a <code>Dicop::Proxy</code> at the same machine (or another
machine if desired), and switch that proxy to SSL and point it to your main
server as it's upstream server.</p>

<p>All clients that support SSL must then connect via that proxy, while all
others must use the server directly. Here is a picture showing the setup:</p>

<pre>
        +---------------+   TCP  +---------------+
        | Server (tcp)  |&lt;-------| Proxy (ssl)   |
        +---------------+        +---------------+
                ^                       ^
                | TCP                   | SSL
                |                       |
        +---------------+        +---------------+
        | Client (tcp)  |        | Client (ssl)  |
        +---------------+        +---------------+</pre>

<p>Note that the connection to the file server is independend of the connection
to the server/proxy.</p>

<p>Please see <code>perldoc doc/Dicop.pod</code> for more details.</p>

</ul>



</div>

<h2><a name="new_features">NEW FEATURES</a></h2>

<div class="text">
<ul>
<li>Setting up a complete new server is now made easier with the included script
<code>./setup</code>. Run it to generate the necessary config files, mail and event
templates, user and group settings, as well as to change the permissions.



<li>Dicop now contains cases, which are just containers to group jobs
together. This will help you to manage many jobs more easier. Each job now
must belong to exactly one case. If there are no cases upon loading the data,
a default case will be created and all jobs added to this case. You can later
modify the case, create now ones as well as move jobs from one case to another
via the web interface.

<p>Apart from viewing the case details including a list of jobs belonging to that
case, you can also get a complete list of all existing cases via the menu in the
footer.</p>



<li>New config field <code>case_url_format</code>. Cases (see previous item) have an URL
field, and if that URL field is empty, it will be automatically generated
from that config key and the current case whenever you view a case via the
HTML interface. This means you do not have to type all URLs manually in,
and changing them all later on is as easy as editign the config and restarting
the server process.

<p>This feature allows you to link your cases to a case database from DiCoP.</p>



<li>New config field <code>send_event_url_format</code>. If defined, the DiCoP server will
send events like new job, job finished or result found to that URL by
using the templates from <code>tpl/event/</code>.



<li>Client's now support the config option <code>sub_arch</code>. If this field is set, the
client will append it to the architecture name and send it to the server.
For instance, two clients runnning under Linux could have <code>sub_arch</code> set
to <code>i386</code> and <code>ia64</code> and the server would then receive <code>linux-i386</code>
and &gt;linux-ia64&gt;, respectively.

<p>The difference would be that the server first tries to serve files from the
sub directory named after the sub-architecture, and then one up, and so on.
Here is an example for the architecture string 'linux-i386-amd', the server
would look into this directories to serve a worker file to the client:</p>

<pre>
                worker/linux/i386/amd
                worker/linux/i386
                worker/linux/</pre>

<p>This allows OS or CPU specific overrides to be specified on a per-client
basis.</p>



<li>A new field in jobtypes allows you to define extra files that need to be
downloaded by the client for the worker. The files are architecture-dependend 
or architecture-independed ('all'). See also above for the new client's
sub-arch feature, you can enter as architecture either the base architecture,
like <code>linux</code>, or the full architecture string like <code>linux-i386</code>.

<p>In the first case all clients running under linux would get the extra file,
in the second case only these reporting exactly <code>linux-i386</code> would get it.
</p>

<pre>

=item *</pre>

<p>The list of all open chunks now also shows chunks in the VERIFY state.</p>



<li>Entry fields that require a filename (like job or testcase target fields) have
a browse button which enables you to select the file from a direcrory view.



<li>The client sends now upon failure the output from the worker as error
message to the server. The last error message and the time it was generated can
be seen on the server's client status page for each client.



<li>The server now tracks the time for each connect, and the server status page
displays a running average, the overall time and the time it took for the last
connect. These times include all the overhead per connect, e.g. not just the
time to generate the answer page.



<li>Several error messages regarding daemon startup have been made more clear,
providing hints on how to fix the problems. A new script called <code>setup</code>
will also help for setting up a server for the first time.



<li>Support for chunk description files (CDF) is now complete. If extra parameters
are necessary on a chunk-by-chunk basis, the server will generate a CDF and
tell the client to:
<pre>
        * download this file
        * pass it to the worker and
        * afterwards delete it</pre>

<p>The client now also supports this fully. This feature is important for special
charsets like Dictionary or Extract sets, because these have parameters (like
file offsets) that change for every chunk.</p>

<p>The <em>job description files</em> are still supported and used when their are
parameters that are necessary for a job, but are equal for all chunks.</p>



<li>In addition to the now fully supported JDF/CDF (see above), the server and
client now support ``inline'' files. For short files (just like CDF/JDF), the
server inlines the file data into the answer sent to the client, which extracts
and stores it. This saves the client from asking the server for the download
location and downloading the file from the file server.



<li>It is now possible to disable testcases. Each testcase can be disabled on it's
own. This allows you to temp. disable testcases that are known not to work.

</ul>



</div>

<h2><a name="known_issues">KNOWN ISSUES</a></h2>

<div class="text">
<dl>
<dt><strong><a name="item_ssl_support">SSL Support</a></strong><br />
</dt>
<dd>
SSL support does not actually work. We are still investigating why.
</dd>



<dt><strong><a name="item_event_posting">Event Posting</a></strong><br />
</dt>
<dd>
Events (job finished, job started etc) will be done while the current
request is worked on. If the remote server is down or slow, this may
cause the request to be stalled or aborted. Events should be posted
outside the main request handling loop, just as emails are being sent.
</dd>
<dd>

<p>We plan to implement this soon.</p>

</dd>



<dt><strong><a name="item_selecting_files_2fdirs_with__27__27">Selecting files/dirs with '_'</a></strong><br />
</dt>
<dd>
It is no longer possible to select files with ``_'' in the name after you have
hit ``Reload'' on the file selector page.
</dd>



<dt><strong><a name="item_dirs_without_proper_permission">Dirs without proper permission</a></strong><br />
</dt>
<dd>
These cause an unknown error instead of a more readable ``permission denied''
when selecting files and directories.
</dd>

</dl>



</div>

<h2><a name="caveats">CAVEATS</a></h2>

<div class="text">
<dl>
<dt><strong><a name="item_obsolete_config_settings">Obsolete config settings</a></strong><br />
</dt>
<dd>
The config setting <code>is_proxy</code> is obselete and no longer supported. Please
remove the appropriate line from your config file. The daemon will warn and
refuse to start if it is still present.
</dd>



<dt><strong><a name="item_old_browser">Old browser</a></strong><br />
</dt>
<dd>
The HTML interface now uses CSS quite extensively. Old browsers without CSS
support (like Netscape 4.x) or with incomplete CSS support (like Konqueror
before 3.2, Internet Explorer 5.x etc) will have problems rendering the
interface properly. It should be still usable, but it will not be pretty.
</dd>
<dd>

<p>Especially in the light of security and looming exploits, we strongly
encourage you to upgrade your browser to the newest version.</p>

</dd>

</dl>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2005</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.</p>



</div>


