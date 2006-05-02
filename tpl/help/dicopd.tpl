

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Dicopd</h1>

<!-- topic: Details for the dicopd daemon. -->

<div class="text">

<p>
Details for the dicopd daemon.
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#overview">OVERVIEW</a></li>
	<ul>

		<li><a href="#installing">Installing</a></li>
		<li><a href="#starting">Starting</a></li>
		<li><a href="#connecting_to_it__administration">Connecting to it, Administration</a></li>
		<li><a href="#troubleshooting">Troubleshooting</a></li>
		<li><a href="#port__group__user">PORT, GROUP, USER</a></li>
		<li><a href="#chroot">CHROOT</a></li>
	</ul>

	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>Last update: 2004-11-25</p>

</div>



<h2><a name="overview">OVERVIEW</a></h2>

<div class="text">

<p><code>dicopd</code> is the master server daemon. Use the <code>Dicop::Proxy</code> package
if you want to setup a proxy.</p>



</div>

<h3><a name="installing">Installing</a></h3>

<div class="text">

<p>Follow the instructions in INSTALL before you attempt to start the daemon.</p>



</div>

<h3><a name="starting">Starting</a></h3>

<div class="text">

<p>To start the daemon in the foreground, type</p>

<pre>
        ./dicopd</pre>

<p>It is recommended to run it in the background, as well as redirect its STDERR
output to a file with:</p>

<pre>
        ./dicopd 2&gt;stderr.txt &amp;</pre>

<p>You can then follow the startup phase with <code>tail -f stderr.txt</code>, which might
take a few seconds to complete.</p>



</div>

<h3><a name="connecting_to_it__administration">Connecting to it, Administration</a></h3>

<div class="text">

<p>You can connect with any webbrowser to the running daemon like it where a web
server. If your daemon is on IP 192.168.0.1 and listening on port 8888 (the
default), then connect to:</p>

<pre>
        <a href="http://192.168.0.1:8888/">http://192.168.0.1:8888/</a></pre>

<p>From there on you should be able to navigate through the pages.</p>



</div>

<h3><a name="troubleshooting">Troubleshooting</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_taint_checking">Taint checking</a></strong><br />
</dt>
<dd>
Please note that
</dd>
<dd>
<pre>
        perl dicopd</pre>
</dd>
<dd>

<p>will not work, since then the taint checking won't work. You must either start
it with <code>-T</code> on the commandline like this:</p>

</dd>
<dd>
<pre>
        perl -w -T dicopd</pre>
</dd>
<dd>

<p>or this:</p>

</dd>
<dd>
<pre>
        ./dicopd</pre>
</dd>



<dt><strong><a name="item_ssh">ssh</a></strong><br />
</dt>
<dd>
When using <a href="#item_ssh"><code>ssh</code></a> to connect to a machine, and then starting the daemon from
there, it is possible that the daemon is killed when you simple close the
terminal window. You need to logout first, the logout might hang, but you can
then safely close the terminal window.
</dd>

</dl>



</div>

<h3><a name="port__group__user">PORT, GROUP, USER</a></h3>

<div class="text">

<p>The port to bind on, the user and group can be set in <code>config/server.cfg</code>. You
should, for security reasons, create a new user and group for the daemon.</p>

<p>Please make sure that the user and group actually exist, or the daemon will not
start.</p>



</div>

<h3><a name="chroot">CHROOT</a></h3>

<div class="text">

<p>Setting the <code>chroot</code> key in the config file to an non-empty string will cause
the daemon to attempt to change the root directory to the specified directory
while running. The usual setting is:</p>

<pre>
        chroot  = &quot;.&quot;</pre>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.</p>



</div>


