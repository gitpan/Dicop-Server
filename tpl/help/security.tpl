

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Security</h1>

<!-- topic: Security aspects of the server, clients and workers. -->

<div class="text">

<p>
Security aspects of the server, clients and workers.
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#protection_against_exploits">PROTECTION AGAINST EXPLOITS</a></li>
	<ul>

		<li><a href="#possible_exploit_types">Possible exploit types</a></li>
		<li><a href="#basic_countermeasures">Basic Countermeasures</a></li>
		<li><a href="#extended_countermeasures">Extended Countermeasures</a></li>
	</ul>

	<li><a href="#client_security">CLIENT SECURITY</a></li>
	<ul>

		<li><a href="#additional_settings">Additional settings</a></li>
	</ul>

	<li><a href="#access_control">ACCESS CONTROL</a></li>
	<ul>

		<li><a href="#administration">Administration</a></li>
		<li><a href="#status_pages">Status pages</a></li>
		<li><a href="#requesting_and_reporting_work_and_testcases">Requesting and reporting work and testcases</a></li>
	</ul>

	<li><a href="#work_integrity">WORK INTEGRITY</a></li>
	<ul>

		<li><a href="#reasons_for_false_data">Reasons for false data</a></li>
		<li><a href="#trusted_vs__untrusted_clients">Trusted vs. untrusted clients</a></li>
		<li><a href="#guarding_against_errors_and_bugs">Guarding against errors and bugs</a></li>
		<li><a href="#hampering_with_the_client">Hampering with the client</a></li>
		<li><a href="#hampering_with_the_worker">Hampering with the worker</a></li>
		<li><a href="#verifying_client_results">Verifying client results</a></li>
		<li><a href="#verifying_client_solutions">Verifying client solutions</a></li>
		<li><a href="#verifying_client_nonsolutions">Verifying client non-solutions</a></li>
		<li><a href="#introducing_chunk_crc">Introducing chunk CRC</a></li>
	</ul>

	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>Last update: 2004-08-23</p>

</div>

<p>This document deals with topics like how to prevent unauthorized access,
denial of service attacks and related topics.</p>



<h2><a name="protection_against_exploits">PROTECTION AGAINST EXPLOITS</a></h2>

<div class="text">

<p>One class of possible security problem are remote exploits against the server
and/or client machines.</p>



</div>

<h3><a name="possible_exploit_types">Possible exploit types</a></h3>

<div class="text">

<p>There are basically two types of remote exploits:</p>

<dl>
<dt><strong><a name="item_invalid_input_executed_as_code">Invalid input executed as code</a></strong><br />
</dt>
<dd>
Certain input to the server process might be given to a shell or a client
to be executed. For instance, the data <code>rm -fR *</code> would delete all files
in the current directory including subdirectories, if executed by the
shell.
</dd>



<dt><strong><a name="item_buffer_overflows">Buffer overflows</a></strong><br />
</dt>
<dd>
Some input might not fit into pre-allocated, fixed-size buffers, thus
overwriting other memory locations, notable the stack. This results in
arbitray code to be executed.
</dd>

</dl>



</div>

<h3><a name="basic_countermeasures">Basic Countermeasures</a></h3>

<div class="text">

<p>The server process is basically a Perl script. This provides a very good
protection against buffer overflows, since all storage in Perl is dynamically
allocated and it is not possible to ``overflow'' a string, for instance.</p>

<p>The only possible problem with huge inputs would be that they could crash the
server due to a ``out of memory'' problem. However, since the server runs
in a loop catching exceptions, this might only affect one connection, not the
entire server process.</p>

<p>To protect against malicius input, the server always runs in <strong>taint</strong> mode,
meaning that all user input (as well as any other external data) is
automatically tainted, and any data comming into contact with the tainted data
is also tainted. Furthermore, tainted data cannot be executed as shell code
or send to the shell as parameters, this is checked by Perl itself, not
the server's Perl code.</p>

<p>A special filter filters out only good characters (typically 'a'..'z',
'A'..'Z' and '0'..'9'), thus effectively preventing tricks like <code>;rm -fR *</code>
from working.</p>

<p>Furthermore, all input is strictly checked. For instance, if two possible
input string could be <code>foo</code> and <code>bar</code>, than we check that the input is
really either <code>foo</code> or <code>bar</code> and deny anything else. If there was only a
check for <code>foo</code> and treating anything else automatically as <code>bar</code>, we
would allow arbitray input to be processed later on, which might cause
unintended consequences.</p>



</div>

<h3><a name="extended_countermeasures">Extended Countermeasures</a></h3>

<div class="text">

<p>While a Perl deamon running in <code>tain</code> mode offers a good protection, it is
not foolproof. There might be some exploits that still work and execute
arbitrary code. For instance, bugs in Perl itself, in third-party code or
in our own code might expose holes that allow malicius input from the outside
to crash the server (effectively a DOS), or even allow execution of
arbitray code on it.</p>

<p>While this is a theoretically problem at the moment, since we are not aware of
any exploits, however, pretending it does not exist will not protect us from
exploits found in the future.</p>

<p>To counter future exploits and limit the damage they could do, we also do:</p>

<dl>
<dt><strong><a name="item_run_as_low_2dprivileged_user_2fgroup">run as low-privileged user/group</a></strong><br />
</dt>
<dd>
The server does switch the process to a different user and group after
the startup phase. Thus any exploit would only be executed with the
premissions and rights of this special user and group, instead of <code>root</code>.
This greatly limits the damage that can be done, and makes full exploits much
harder (for a full root exploit, the exploit code not only needs to break out
of the tainted Perl environment, but it also needs a local-root exploit as
well).
</dd>



<dt><strong><a name="item_chroot"><code>chroot()</code> to the server directory</a></strong><br />
</dt>
<dd>
Also, after the startup phase the server is changing the root dir via
<a href="#item_chroot"><code>chroot()</code></a> to it's own local directory. This means the server process can no
longer access any files outside of this directory, since they just don't exist
for it at all.
</dd>
<dd>

<p>The exploit's damage is thus limited to the actual server directory itself
(Or the exploit would also need to carry an additional way of breaking out of
the <a href="#item_chroot"><code>chroot()</code></a> environment, which might not even possible at all - since
the usage of the <a href="#item_chroot"><code>chroot</code></a> command under Perl is limited to the root user).</p>

</dd>

</dl>

<p>To strengthen the server even further, the normal security patches that
randomize heap, stack and libc addresses (like PAX) should also be employed,
together with keeping the kernel and software current.</p>



</div>

<h2><a name="client_security">CLIENT SECURITY</a></h2>

<div class="text">

<p>Just like the server should not trust the clients, the clients should
not trust the server. This means that data from the server needs to be
checked, limited, and validated before passed on to the worker. Otherwise
somebody might either fake a server or hack the main server and then exploit
all client machines by sending them malicius responses.</p>



</div>

<h3><a name="additional_settings">Additional settings</a></h3>

<div class="text">

<p>The client also knows the <code>user</code>, <code>group</code> and <a href="#item_chroot"><code>chroot</code></a> settings from
either the config file or on the command line.</p>

<p>After starting the client as root, the client will change the process to
run under the given user and group. (It will also complain if it is supposed
to run as root).</p>

<p>The <a href="#item_chroot"><code>chroot()</code></a> functionality for the client does currently not work, due to
the problem of auto-loading different libraries afterwards.</p>

<p>Enabling at least the user/group setting or running the client as a non-root
user from start is highly recommended, since this limits the damage an
potential exploit of the client or worker could do!</p>

<p>The client also limits the lengths of the data given to the worker, thus
preventing potential buffer-overflows.</p>



</div>

<h2><a name="access_control">ACCESS CONTROL</a></h2>

<div class="text">

<p>The access to the server needs to be restricted so that only authorized
machines and persons can administrate the server, view status pages, and
that only authorized clients can work on the cluster.</p>



</div>

<h3><a name="administration">Administration</a></h3>

<div class="text">

<p>For submitting changes to the server, the administrator needs to authenticate
herself. She does this by filling in a username and password.</p>

<p>Currently username and password are transmitted in cleartext over the network.</p>

<p>Without the proper username and password, the change is denied.</p>

<p>New administrator accounts can be added by choosing the ``Add User'' form and
filling it in. This form also needs an authentication from an administrator,
which means it is not possible to enter the first administrator account via
the HTTP interface.</p>

<p>To add the first user, follow these steps:</p>

<dl>
<dt><strong><a name="item_shut_down_the_daemon">shut down the daemon</a></strong><br />
</dt>
<dd>
If the dicopd daemon is running, stop it.
</dd>



<dt><strong><a name="item_run_adduser_2epl">run adduser.pl</a></strong><br />
</dt>
<dd>
Follow the instructions.
</dd>



<dt><strong><a name="item_restart_the_daemon">restart the daemon</a></strong><br />
</dt>
</dl>



</div>

<h3><a name="status_pages">Status pages</a></h3>

<div class="text">



</div>

<h3><a name="requesting_and_reporting_work_and_testcases">Requesting and reporting work and testcases</a></h3>

<div class="text">



</div>

<h2><a name="work_integrity">WORK INTEGRITY</a></h2>

<div class="text">



</div>

<h3><a name="reasons_for_false_data">Reasons for false data</a></h3>

<div class="text">

<p>False data can occur due to software bugs, hardware errors (for instance
memory corruption or other data corruption due to (intermidiate) hardware
failure, or malicius intent.</p>

<p>Especially when running untrusted clients (e.g. software on machine you do not
have 100% control over) and displaying public statistics, the chances are
high that someone will try to modify the client to send in results faster
to get higher up in the stats. Basically this can be done by not doing any
real work, just pretending it. Thus more chunks per time unit can be <em>done</em>,
which results in better statistics for him, and wrong data for us.</p>



</div>

<h3><a name="trusted_vs__untrusted_clients">Trusted vs. untrusted clients</a></h3>

<div class="text">

<p>An easy way to avoid malicius hampering is running only trusted clients, e.g.
machines that are under our control. This is, however, not always possible
and still does not guard against bugs or faults.</p>



</div>

<h3><a name="guarding_against_errors_and_bugs">Guarding against errors and bugs</a></h3>

<div class="text">

<p>One step to make sure that a client cannot report results or data for other
clients is to authenticate each client.</p>



</div>

<h3><a name="hampering_with_the_client">Hampering with the client</a></h3>

<div class="text">

<p>The client is public, and thus hampering with it is very easy. Nothing what
the client reports should be trusted.</p>

<p>Currently, some things the client reports are taken with much verification,
this needs changing.</p>



</div>

<h3><a name="hampering_with_the_worker">Hampering with the worker</a></h3>

<div class="text">



</div>

<h3><a name="verifying_client_results">Verifying client results</a></h3>

<div class="text">

<p>A client may report wrong status codes for a chunk, either by error (software
or hardware bugs) or by malicius intend.</p>

<p>There are two possible sources of false client results:</p>

<dl>
<dt><strong><a name="item_false_positives">False positives</a></strong><br />
</dt>
<dd>
A false positive is a reported result in one chunk, where there was really no
result or solution in that chunk, or the result was in that chunk, but at a
different key.
</dd>
<dd>

<p>These are easily to generate, a client just needs to send in a result for each
chunk.</p>

</dd>
<dd>

<p>False positives are non-critical, since they can be verified very easily.</p>

</dd>



<dt><strong><a name="item_false_negatives">False negatives</a></strong><br />
</dt>
<dd>
A false negative is a chunk where there should have been a solution, but the
client did not find it.
</dd>
<dd>

<p>Since solutions occur to so seldom, these false negatives are actually hard
to produce. If a client would send always a status of DONE, a false negative
would only occur when there should have been a solution, which is almost
never. However, false negatives are critical when they occur, since they
would make us miss the solution, very probably requiring the entire job
to be redone.</p>

</dd>

</dl>



</div>

<h3><a name="verifying_client_solutions">Verifying client solutions</a></h3>

<div class="text">

<p>This is quite easily, each chunk with a reported solution is handed to at least
one second client, which are asked to verify the solution. Only if all of them
agree on the solution, the result is accepted.</p>



</div>

<h3><a name="verifying_client_nonsolutions">Verifying client non-solutions</a></h3>

<div class="text">

<p>The same method to verify SOLVED chunks can be used to verify DONE chunks,
each chunk is handed out to multiple clients, which all need to verify the
chunk. However, this is not enough.</p>

<p>Imagine that 10% of all clients are faking all chunks, simple returning DONE
without doing any work at all.</p>

<p>If we get such a fake chunk (a false negative, e.g. a chunk which contains a
result, but is given back as DONE, making us thinking it doesn't contain a
result), and hand it to another client, the chances that the second client is
also faking it's return result are very high. This means that we would never
detect that the chunk was false and thus miss the result entirely.</p>



</div>

<h3><a name="introducing_chunk_crc">Introducing chunk CRC</a></h3>

<div class="text">

<p>The chunk CRC is calculated by the worker, and should be based on plaintext
data that depends on each key that is tried (not the key itself). This means
it will be very hard to generate the right CRC (e.g. fake it) without going
through all the actual work for each key. This is the entire purpose of the
CRC.</p>

<p>With the CRC reported back to the server, we can spot clients that report false
DONE chunks, by letting their work being verified by a different client.</p>

<p>If the second client is not also faking the CRC (if it is, the CRC can and will
be the same fake value, since the bad clients can either communicate with
each other, or just base the CRC on the public data of the chunk, like start
and end), the second CRC will not match the first CRC. This way we know that
one of the reported chunks was a fake.</p>

<p>We don't know which one, but we can mark both clients as suspicious, and if
one of them is involved in another suspicious activity, we can shut it down
by denying it further work.</p>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.</p>



</div>


