

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Trouble</h1>

<!-- topic: Troubleshooting -->

<div class="text">

<p>
Troubleshooting
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#overview">OVERVIEW</a></li>
	<li><a href="#questions_and_answers">QUESTIONS AND ANSWERS</a></li>
	<ul>

		<li><a href="#the_daemon_does_not_start__or_immidiately_stops_without_any_message">The daemon does not start, or immidiately stops without any message</a></li>
		<li><a href="#what_does_the_request_rate_limit_was_reached_mean">What does ``The request rate limit was reached'' mean?</a></li>
		<li><a href="#i_have_a_chunk_called_verify__but_nothing_more_happens">I have a chunk called ``VERIFY'', but nothing more happens</a></li>
		<li><a href="#missing_links_in_the_menu_when_using_the_default_html_style">Missing links in the menu when using the default HTML style</a></li>
		<li><a href="#the_daemon_complains_about_missing_mail_templates_on_startup">The daemon complains about missing mail templates on startup?</a></li>
		<li><a href="#messages_like_param__speed__of_cmd__add___type__jobtype__is_empty">Messages like ``Param 'speed' of cmd 'add', type 'jobtype' is empty''</a></li>
		<li><a href="#_htpasswd_not_possible_as_target_file">``.htpasswd'' not possible as target file</a></li>
		<li><a href="#my_external_scripts__for_target_extraction__do_not_run">My external scripts (for target extraction) do not run</a></li>
	</ul>

	<li><a href="#author">AUTHOR</a></li>
	<li><a href="#contact">CONTACT</a></li>
</ul>
</div>


<p>Last update: 2004-11-25</p>

</div>



<h2><a name="overview">OVERVIEW</a></h2>

<div class="text">

<p>This document provides you with help for certain troubling moments that
are often experienced, but have (usually :) a simple solution.</p>



</div>

<h2><a name="questions_and_answers">QUESTIONS AND ANSWERS</a></h2>

<div class="text">



</div>

<h3><a name="the_daemon_does_not_start__or_immidiately_stops_without_any_message">The daemon does not start, or immidiately stops without any message</a></h3>

<div class="text">

<p>Answer:</p>

<ul>
<li>Run the daemon dicopd in the foreground, to see possible error messages.



<li>Look into logs/error.log and logs/server.log for error messages.



<li>Check that all files in <code>logs/</code> are writeable by the user/group you want the
daemon to run under. F.i. running it under user=dicop, group=dicop means
that <code>logs/</code>, <code>logs/error.log</code> and <code>logs/server.log</code> must be writable by user
dicop.

</ul>



</div>

<h3><a name="what_does_the_request_rate_limit_was_reached_mean">What does ``The request rate limit was reached'' mean?</a></h3>

<div class="text">

<p>Answer:</p>

<p>Each client may not connect more than a couple of times per hour to the
server. So if a client is too fast, it will be slowed down by the server.
You are most likely to encounter it while testing things out. In these
cases just add another client and use this instead of the first one.</p>

<p>You can also go to the client's individual status page and reset the
client's data from there, this will reset the connection counter and
allow more connects from this client.</p>



</div>

<h3><a name="i_have_a_chunk_called_verify__but_nothing_more_happens">I have a chunk called ``VERIFY'', but nothing more happens</a></h3>

<div class="text">

<p>Answer:</p>

<p>When a client finds a solution, the chunk with the solution in it is
going to the verify state, and waits to be verified by some more clients.
How many clients are needed to finally verify a solution can be set in the
config file.</p>

<p>However, a chunk cannot be verified by the same client, so you really need
a different client to finally ``find'' the solution.
Also, chunks in the verify state cannot be split up, so you need to watch
out that the other client is not too slow (otherwise the VERIFY chunk is
considered to big and will not be verified by the other client for quite
a while).</p>



</div>

<h3><a name="missing_links_in_the_menu_when_using_the_default_html_style">Missing links in the menu when using the default HTML style</a></h3>

<div class="text">

<p>Answer:</p>

<p>Delete <code>tpl/styles/Default/footer.txt</code> and <code>tpl/styles/Default/header.txt</code> -
they contain older versions, are no longer necc. and needlessly overwrite the
files in <code>tpl/</code>.</p>



</div>

<h3><a name="the_daemon_complains_about_missing_mail_templates_on_startup">The daemon complains about missing mail templates on startup?</a></h3>

<div class="text">

<p>Answer:</p>

<p>Make sure you have:</p>

<pre>
        mailtxt_dir = mail</pre>

<p>in your config file (and not <code>tpl/mail</code>). The prefix will be automatically
added from whatever your <code>tpl_dir</code> setting in the server config is.</p>

<p>Also, did you remember to rename the sample mail text files in that
directory by removing the <code>.sample</code> prefix?</p>



</div>

<h3><a name="messages_like_param__speed__of_cmd__add___type__jobtype__is_empty">Messages like ``Param 'speed' of cmd 'add', type 'jobtype' is empty''</a></h3>

<div class="text">

<p>What does it mean and what do I do?</p>

<p>Answer:</p>

<p>You accidentily did not provide a value for some field when filling out a form
to add or edit something. Use your browser's backbutton and retry the action.</p>

<p>If you tried to fill in a '0', and the same message still appears, the value
you enter cannot be zero. If you think it should allow zero or empty string
at that place, then please file a bug report with us. See CONTACT details
at bottom.</p>



</div>

<h3><a name="_htpasswd_not_possible_as_target_file">``.htpasswd'' not possible as target file</a></h3>

<div class="text">

<p>It seems I cannot provide a file called '.htpasswd' to any client or worker
as a target file? The filename seems to be passed along to the client
properly, but the client simple cannot download the file. I get an error
message like: ``403 Forbidden''.</p>

<p>Answer:
</p>

<pre>

This is actually a security check done by the Apache server, it denies
downloads of files that start with C&lt;.htpasswd&gt; to prevent tampering with
the server itself. You can work around that by either calling the file
C&lt;htpasswd&gt; or use an FTP file server or use a different HTTP server.</pre>

<p>It would not be a wise idea to allow you Apache to serve <code>.htpasswd</code> files
to the client, however, since this compromises the security of the Apache.</p>



</div>

<h3><a name="my_external_scripts__for_target_extraction__do_not_run">My external scripts (for target extraction) do not run</a></h3>

<div class="text">

<p>When trying to run an external script to extract a target file, the server
always outputs an error, even though all the permissions etc seem to be right.</p>

<p>Answer:</p>

<p>Check that <code>chroot</code> in the <code>server.cfg</code> config file is <strong>disabled</strong>.
Currently, under chroot, the external script is likely to miss dynamically
loaded libararies and files and thus fails to run.</p>

<p>Alternatively, you can copy all the files into the chroot path.</p>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(C) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004.</p>

<p>For licensing information please refer to the LICENSE file.</p>



</div>

<h2><a name="contact">CONTACT</a></h2>

<div class="text">
<pre>
        Address: BSI
                 Referat I2.3
                 Godesberger Alle 185-189
                 Bonn
                 53175
                 Germany
        email:   dicop@bsi.bund.de              (for public key see dicop.asc)
        www:     <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a></pre>



</div>


