

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Glossary</h1>

<!-- topic: Glossary with often used acronyms or words. -->

<div class="text">

<p>
Glossary with often used acronyms or words.
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<ul>

		<li><a href="#a">A</a></li>
		<li><a href="#c">C</a></li>
		<li><a href="#d">D</a></li>
		<li><a href="#f">F</a></li>
		<li><a href="#g">G</a></li>
		<li><a href="#h">H</a></li>
		<li><a href="#j">J</a></li>
		<li><a href="#n">N</a></li>
		<li><a href="#p">P</a></li>
		<li><a href="#k">K</a></li>
		<li><a href="#r">R</a></li>
		<li><a href="#s">S</a></li>
		<li><a href="#t">T</a></li>
		<li><a href="#u">U</a></li>
		<li><a href="#w">W</a></li>
		<li><a href="#v">V</a></li>
	</ul>

	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>Last update: 2004-12-22</p>

</div>



<h3><a name="a">A</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_argument">argument</a></strong><br />
</dt>
<dd>
A <a href="#item_request">request</a> has arguments (also called parameters), just like a
command on the command line has (think of <code>ls -la</code>).
</dd>
<dd>

<p>An example:</p>

</dd>
<dd>
<pre>
        cmd_status;type_main</pre>
</dd>
<dd>

<p>Here the two arguments are <strong>cmd</strong> and <strong>type</strong>.</p>

</dd>



<dt><strong><a name="item_administrator">administrator</a></strong><br />
</dt>
<dd>
An administrator (also refered to as <a href="#item_user"><code>user</code></a>) can view all pages on the
<a href="#item_server"><code>server</code></a>, as well as change them, add new objects (jobs, charsets etc).
</dd>
<dd>

<p>He/she needs an user account for that. The first account has to be added
to the server before it is started (for security reasons), all other
accounts can be added/edited/deleted by any of the administrators.</p>

</dd>
<dd>

<p>Currently all administrators have the same rights.</p>

</dd>

</dl>



</div>

<h3><a name="c">C</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_case">case</a></strong><br />
</dt>
<dd>
Cases are used to group <a href="#item_job">jobs</a> together, each job must belong to
exactly one case.
</dd>



<dt><strong><a name="item_cdf">CDF</a></strong><br />
</dt>
<dd>
A <code>Chunk Description File</code>. Carries extra options necessary for a chunk
like charset parameters (prefix, dictionaries etc) or job parameters
(like extra params).
</dd>
<dd>

<p>For a detailed specification see the file <code>doc/Config.pod</code> in the
<code>Dicop::Workerframe</code> package.</p>

</dd>



<dt><strong><a name="item_charset">charset</a></strong><br />
</dt>
<dd>
A charset describes the keyspace of a job, e.g. what keys are part of the
keyspace and what not. The charset is also responsible for mapping between
the keys in the keyspace and a consequtive numberspace that goes from 1 to
the number of the last key.
</dd>



<dt><strong><a name="item_charset_description_file">charset description file</a></strong><br />
</dt>
<dd>
These are now known as <a href="#job_description_file">job description file</a> or <a href="#item_jdf">JDF</a> for short.
</dd>



<dt><strong><a name="item_charsets_2edef">charsets.def</a></strong><br />
</dt>
<dd>
<a href="#item_charsets_2edef"><code>charsets.def</code></a> is a file describing all the different charsets, so that a
worker knows what charset number X looks like, and which keys belong to
the <a href="#item_keyspace">keyspace</a> of it.
</dd>



<dt><strong><a name="item_checklist">checklist</a></strong><br />
</dt>
<dd>
When a solution is found for one job, a small chunk with this result will
be added to the <a href="#item_checklist"><code>checklist</code></a> of all running jobs with the same jobtype.
</dd>



<dt><strong><a name="item_chunk">chunk</a></strong><br />
</dt>
<dd>
A (usually small) part of the keyspace. All chunks together in the
<a href="#item_chunklist">chunklist</a> of a <a href="#item_job">job</a> make out the <a href="#item_keyspace">keyspace</a>.
</dd>



<dt><strong><a name="item_chunklist">chunklist</a></strong><br />
</dt>
<dd>
All <a href="#item_chunk">chunks</a> in this list together form the <a href="#item_keyspace">keyspace</a>.
</dd>



<dt><strong><a name="item_client">client</a></strong><br />
</dt>
<dd>
The word client has three meanings:
</dd>
<dd>
<pre>
        * The client machine/hardware, see L&lt;node&gt;.</pre>
</dd>
<dd>
<pre>
        * And the client software running on the client machine.
          This software requests work from a L&lt;server&gt; or L&lt;proxy&gt;,
          feeds it to the L&lt;worker&gt; and sends the result back to
          the server. Clients belong to a L&lt;group&gt;, but they never
          talk with each other.</pre>
</dd>
<dd>
<pre>
        * The internal server object representing a client.
          Each client has to be registered (e.g. known) to the server
          before the server will accept L&lt;requests|request&gt; from it.</pre>
</dd>



<dt><strong><a name="item_clientmap">clientmap</a></strong><br />
</dt>
<dd>
The clientmap shows you at one glance the status of all the known clients.
</dd>



<dt><strong><a name="item_connect">connect</a></strong><br />
</dt>
<dd>
Each time a client talks to the server, this counts as one connect. Each
connect can carry multiple <a href="#item_request">requests</a>.
</dd>

</dl>



</div>

<h3><a name="d">D</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_deja_vu">deja vu</a></strong><br />
</dt>
<dd>
The (strong) feeling that something has happened to you before, or you were
already at this place or time. See also <a href="#deja_vu">deja vu</a>.
</dd>



<dt><strong><a name="item_dictionary">dictionary</a></strong><br />
</dt>
<dd>
An alphabetically sorted (just what <code>sort -u</code> produces) list of words stored in a flat
file, e.g. one word per line. Each word can contain arbitrary characters, except
linefeed of course.
</dd>
<dd>

<p>The dictionary file needs to be processed by a small script, which checks it and
generates a checksum. The server will only recognize dictionaries if the checksum
is correct, e.g. the check succeeded.</p>

</dd>

</dl>



</div>

<h3><a name="f">F</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_fileserver">fileserver</a></strong><br />
</dt>
<dd>
Sometimes the <a href="#item_client">client</a> will need to download files, usually
<a href="#item_worker">workers</a> or <a href="#target_files">targetfiles</a>. These are provided by a
so-called fileserver, which is usually just an HTTP or FTP server running at the
same (or another) machine than the <a href="#item_server">main server</a>.
</dd>

</dl>



</div>

<h3><a name="g">G</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_group">group</a></strong><br />
</dt>
<dd>
<a href="#item_client">Clients</a> are organized into groups, mostly for statistical purposes.
</dd>



<dt><strong><a name="item_glitch">glitch</a></strong><br />
</dt>
<dd>
A small change in the matrix. See also <a href="#deja_vu">deja vu</a>.
</dd>

</dl>



</div>

<h3><a name="h">H</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_headnode">headnode</a></strong><br />
</dt>
<dd>
The machine running the <a href="#item_server">server</a> is sometimes referred to as the <a href="#item_headnode"><code>headnode</code></a>.
</dd>

</dl>



</div>

<h3><a name="j">J</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_jdf">JDF</a></strong><br />
</dt>
<dd>
A <code>Job Description File</code>. This carries extra options necessary for a particular
job, like a fixed prefix, extra params etc.
</dd>
<dd>

<p>For a detailed specification see the file <code>doc/Config.pod</code> in the
<code>Dicop::Workerframe</code> package.</p>

</dd>



<dt><strong><a name="item_job">job</a></strong><br />
</dt>
<dd>
A job is what you use to find a solution or password for, f.i. it might be
some sort of encryption which uses a password as key. The job contains the
<a href="#item_keyspace">keyspace</a> to be searched as well as additional options that
describe the kind of job.
</dd>



<dt><strong><a name="item_job_description_file">job description file</a></strong><br />
</dt>
<dd>
Please see <a href="#item_jdf">JDF</a> for details.
</dd>



<dt><strong><a name="item_jobtype">jobtype</a></strong><br />
</dt>
<dd>
Each job has a jobtype, which describes which worker to use for this job.
</dd>

</dl>



</div>

<h3><a name="n">N</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_node">node</a></strong><br />
</dt>
<dd>
A node is one client machine in the cluster, running the <a href="#item_client">client</a> and
<a href="#item_worker">worker</a> (one worker at a time).
</dd>
<dd>

<p>In a DiCoP cluster, nodes can be of any size, speed and architecture. The nodes
never need to talk to each other, which means their raw CPU power is much
more important than their network speed - theoretically they could work
over dial-up or email just fine.</p>

</dd>
<dd>

<p>See also <a href="#item_headnode">headnode</a>.</p>

</dd>

</dl>



</div>

<h3><a name="p">P</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_parameter">parameter</a></strong><br />
</dt>
<dd>
See <a href="#item_argument">arguments</a>.
</dd>



<dt><strong><a name="item_proxy">proxy</a></strong><br />
</dt>
<dd>
A special server acting as a proxy or bridge. It can help clients to cross
network segments, and caches certain information to reduce the load on the
<a href="#item_server">main server</a>. Use the package <code>Dicop-Proxy</code> to install a DiCoP proxy.
</dd>

</dl>



</div>

<h3><a name="k">K</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_keyspace">keyspace</a></strong><br />
</dt>
<dd>
The key space is the complete list of all keys or passwords for a certain job.
Since it is usually very huge, it is distributed over the <a href="#item_client">clients</a>,
and each of them looks at different pieces of the keyspace. This is what this
project is all about, afterall: distributed computing.
</dd>

</dl>



</div>

<h3><a name="r">R</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_rank">rank</a></strong><br />
</dt>
<dd>
<a href="#item_job">Jobs</a> are ranked by their rank. The job (of all running jobs) with the
lowest rank becomes a
certain percent of all cluster CPU time (usually this is 90%, but can be
changed in the server config file). All other jobs share the rest of the CPU
time equally.
</dd>
<dd>

<p>If there is more than one job with the same, lowest rank, the share the 90%
equally between them.</p>

</dd>
<dd>

<p>When the job with the lowest rank is done, it will be removed from the list
of running jobs. Thus the running <a href="#item_job"><code>job(s)</code></a> with the second-to-lowest rank will
then have the lowest rank, thus getting the highest priority.</p>

</dd>
<dd>

<p>Some examples:</p>

</dd>
<dd>
<pre>
        Job id          job rank        priority assigned
        1               80              90%
        2               90               5%
        3               90               5%</pre>
</dd>
<dd>

<p>Adding another job with rank 70:</p>

</dd>
<dd>
<pre>
        1               80               3.33%  
        2               90               3.33%  
        3               90               3.33%  
        4               70              90%</pre>
</dd>
<dd>

<p>Assuming that job 3 is finished:</p>

</dd>
<dd>
<pre>
        1               80               5%     
        2               90               5%     
        3               90              -       
        4               70              90%</pre>
</dd>
<dd>

<p>Adding another job with rank 70:</p>

</dd>
<dd>
<pre>
        1               80               5%     
        2               90               5%     
        3               90              -
        4               70              45%     
        5               70              45%
        
The priority in percent means that the job will get that much CPU time from
the cluster. In reality, it means that the number of chunks issued to that
job will be approximate this priority. So some errors occur and it only works
out after a couple of chunks have been issued.</pre>
</dd>



<dt><strong><a name="item_request">request</a></strong><br />
</dt>
<dd>
Messages exchanged between the client and the server are called <code>requests</code>.
</dd>
<dd>

<p>Each request has <a href="#item_argument">parameters</a>.</p>

</dd>
<dd>

<p>The client may send multiple <code>requests</code> on each <a href="#item_connect">connect</a>, and the <a href="#item_server">server</a> will
answer with one or more <code>requests</code>.</p>

</dd>
<dd>

<p>If the client is a browser, it will sent usually only one request and the server
will answer with an HTML page.</p>

</dd>



<dt><strong><a name="item_reset">reset</a></strong><br />
</dt>
<dd>
The <a href="#item_server">server</a> stores tables and counters for each client, for instance, how many
failures this client had, how fast it can work on certain jobtypes, etc.
</dd>
<dd>

<p>Since a client will be disallowed from connecting to the server if it had too
many failures, there is a way to reset the client, e.g. pruge these tables. To
do this, go to the client page on the server either via the <a href="#item_clientmap">clientmap</a>,
the client list or the search page and then choose ``Reset'' from the menu.</p>

</dd>



<dt><strong><a name="item_result">result</a></strong><br />
</dt>
<dd>
An result is a solution in the <a href="#item_keyspace">keyspace</a>. There can be only one
result per <a href="#item_chunk">chunk</a>, but usually you care only for the first found
result in a given <a href="#item_job">job</a>, anyway.
</dd>

</dl>



</div>

<h3><a name="s">S</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_server">server</a></strong><br />
</dt>
<dd>
There usually exists only one main (or master) server. It contains all the
data (jobs, testcases, clients etc), manages the keyspaces, hands out work,
displays status pages, let's you administer anything etc. <a href="#item_client">Clients</a>
talk to it directly or via a <a href="#item_proxy">proxy</a>.
</dd>



<dt><strong><a name="item_style">style</a></strong><br />
</dt>
<dd>
The HTML output can have certain styles (think of Cascading Style Sheets, which
are incidentily used to implement this). This is purely asthetic and doesn't
change the working of the cluster in any way.
</dd>

</dl>



</div>

<h3><a name="t">T</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_target">target</a></strong><br />
</dt>
<dd>
A target (or targetfile) is needed by some <a href="#item_job">jobs</a>. Usually a job needs
some small bits of information to be solved, but sometimes it needs a lot more
information. In these cases the information are put into a target file, which
is downloaded by each <a href="#item_client">client</a> and then given to the <a href="#item_worker">worker</a>.
</dd>



<dt><strong><a name="item_template">template</a></strong><br />
</dt>
<dd>
Templates are pre-made files that are used to send customized information from
the server to some client (or user via a browser). They contain
small pieces of text sourrounded by <code>##</code>. Here is an example:
</dd>
<dd>
<pre>
        I know &lt;b&gt;##runningjobs##&lt;/b&gt; running jobs.</pre>
</dd>
<dd>

<p>This template would be processed by the server, filling in the marker with
the number of actually running jos. The result would look like:</p>

</dd>
<dd>
<pre>
        I know &lt;b&gt;2&lt;/b&gt; running jobs.</pre>
</dd>
<dd>

<p>There are templates for the HTML output, and for the emails sent out by the
server.</p>

</dd>



<dt><strong><a name="item_testcase">testcase</a></strong><br />
</dt>
<dd>
A testcase consists of a small <a href="#item_chunk">chunk</a> with a known result, and is sent
to the <a href="#item_client">client</a> to test whether it really works or not. There are two
types of testcases, one with a (known) result and one known to have no result.
</dd>
<dd>

<p>To make sure that a client/worker really works, for each  jobtype there should
be at least two testcases, one with a result, and one without a result.</p>

</dd>

</dl>



</div>

<h3><a name="u">U</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_user">user</a></strong><br />
</dt>
<dd>
There are two definitions of the word user:
</dd>
<dd>

<p>People that run a client and participate in a DiCoP server project are
called users.</p>

</dd>
<dd>

<p>Also, people who aministrate the server are sometimes called users, see
<a href="#item_administrator">administrator</a> for more information.</p>

</dd>

</dl>



</div>

<h3><a name="w">W</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_what_3f">what?</a></strong><br />
</dt>
<dd>
Usually heard uttered by an astonished observer when a <a href="#deja_vu">deja vu</a> happens.
</dd>



<dt><strong><a name="item_worker">worker</a></strong><br />
</dt>
<dd>
A program that works on a part of the key space and reports whether it found a
key or not. Usually written in C or Assembler to be as fast as possible. The
worker is used by the <a href="#item_client">client</a>. See also <a href="#item_workerframe">workerframe</a>.
</dd>



<dt><strong><a name="item_workerframe">workerframe</a></strong><br />
</dt>
<dd>
This is a framework to build workers more easily and is called Dicop-Workerframe.
</dd>
<dd>

<p>This framework anything you need to build a worker in C, plus documentation
and examples.</p>

</dd>

</dl>



</div>

<h3><a name="v">V</a></h3>

<div class="text">
<dl>
<dt><strong><a name="item_verify">VERIFY</a></strong><br />
</dt>
<dd>
Chunks are in the <code>verify</code> state when a client found a solution for this chunk,
but no other client did yet verify the result.
</dd>
<dd>

<p>The number of clients that need to verify each positive (or negative) result
can be set in the server config file.</p>

</dd>
<dd>

<p>The defaults are set so that negative results need not to be verified at all,
and positive results must be verified by at least one other client.</p>

</dd>



<dt><strong><a name="item_vu_2c_deja">vu, deja</a></strong><br />
</dt>
<dd>
The (strong) feeling that something has happened to you before, or you were
already at this place or time. See also <a href="#deja_vu">deja vu</a>.
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


