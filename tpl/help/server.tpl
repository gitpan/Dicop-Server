

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Server</h1>

<!-- topic: This documentations covers the DiCoP server's gory guts. -->

<div class="text">

<p>
This documentations covers the DiCoP server's gory guts.
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#data_structures">DATA STRUCTURES</a></li>
	<ul>

		<li><a href="#joblist">Joblist</a></li>
		<li><a href="#chunklist">Chunklist</a></li>
		<li><a href="#checklist">Checklist</a></li>
	</ul>

	<li><a href="#finding_a_suitable_chunk">FINDING A SUITABLE CHUNK</a></li>
	<li><a href="#calculating_the_chunk_size">CALCULATING THE CHUNK SIZE</a></li>
	<ul>

		<li><a href="#mismatching_size">Mismatching Size</a></li>
	</ul>

	<li><a href="#reading_flushing">READING/FLUSHING</a></li>
	<li><a href="#client_data">CLIENT DATA</a></li>
	<ul>

		<li><a href="#failure_counter">Failure counter</a></li>
	</ul>

	<li><a href="#proxy_list">PROXY LIST</a></li>
	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>Last update: 2004-09-19</p>

</div>



<h2><a name="data_structures">DATA STRUCTURES</a></h2>

<div class="text">



</div>

<h3><a name="joblist">Joblist</a></h3>

<div class="text">

<p>The joblist contains all the jobs that were ever entered into the server. Not
all of them need to be running at the same time, but finished or suspended jobs
will still exist.</p>

<p>Each job has a <a href="#chunklist">chunklist</a>, a <a href="#checklist">checklist</a>,
is of a certain jobtype and carries a certain rank/priority with it. Each job
also has a charset, which describes basically the job's keyspace.</p>



</div>

<h3><a name="chunklist">Chunklist</a></h3>

<div class="text">

<p>Each job has a so-called <em>chunklist</em>. Each chunk corrospondends to a piece
or part of the job's keyspace and all chunks together form the keyspace
of the job.</p>

<p>Chunks can have different status codes as detailed below:</p>

<dl>
<dt><strong><a name="item_tobedone">TOBEDONE</a></strong><br />
</dt>
<dd>
This chunk still needs to be done.
</dd>



<dt><strong><a name="item_done">DONE</a></strong><br />
</dt>
<dd>
Chunk was completely checked and contains no result.
</dd>



<dt><strong><a name="item_solved">SOLVED</a></strong><br />
</dt>
<dd>
Chunk contains a result.
</dd>



<dt><strong><a name="item_issued">ISSUED</a></strong><br />
</dt>
<dd>
Currently issued to a client.
</dd>



<dt><strong><a name="item_failed">FAILED</a></strong><br />
</dt>
<dd>
Client could not complete chunk (either due to error or due to timeout).
This chunk will be re-issued later on.
</dd>



<dt><strong><a name="item_timeout">TIMEOUT</a></strong><br />
</dt>
<dd>
(not implemented yet) Client could not complete chunk in time.
</dd>



<dt><strong><a name="item_verify">VERIFY</a></strong><br />
</dt>
<dd>
One client reported this chunk back. The chunk is now waiting to be verified
by another client. Usually only chunks with a solution will be verified, but
you can change this in the config file, so that each chunk or each Nth chunk
is verified.
</dd>



<dt><strong><a name="item_bad">BAD</a></strong><br />
</dt>
<dd>
This chunk failed to be verified by a client, because the clients did not
agree on what the result for this should be, or if there should be one, or
what the CRC over this chunk is. The chunk will, just like a FAILED one,
re-issued later.
</dd>

</dl>



</div>

<h3><a name="checklist">Checklist</a></h3>

<div class="text">

<p>Each job also has a so-called <em>checklist</em>.</p>

<p>This list contains results (from other jobs) that need to be checked against
this job. It stores chunk numbers and, optionally, results. The checklist will
be consulted before finding a chunk for a client in the chunklist.</p>

<p>To make this possible, chunks in the checklist are as small as possible and
are created as soon as a result is found.</p>

<p>The checklist contains only chunks from jobs with the same jobtype, in the
hope is that the result also applies to this job. Since it is not know what
result (if any) will be found in the chunk to be checked, the checklist does
not contain a result.</p>



</div>

<h2><a name="finding_a_suitable_chunk">FINDING A SUITABLE CHUNK</a></h2>

<div class="text">

<p>To find a suitable chunk for a client, the server first selects a job. This
is done by calculating a random value between 0 and 1 and matching it against
the priorities of the running job. That ensures that the work is distributed
between the jobs in the intended way, e.g. the percentages match up.</p>

<p>The server then walks the chunklist of a potential job until it finds a 
suitable chunk. Suitable chunks are chunks that either match roughly the
size of the work the client requested, or are bigger. In the latter case,
the chunk will be split up and the smaller, suitable part, will be given to
the client.</p>

<p>An exeption to this are VERIFY chunks, to properly verify them, they are never
split up. If a chunk has not been verified for a long time, probably no client
is fast enough to verify the chunk, so it will go back to the TOBEDONE state
and can thus be broken up into smaller parts.</p>

<p>To prevent the server from going over the entire chunk list, the process
selecting a chunk stops as soon as posssible. Also, the server remembers the
first possible chunk to be selected to be given out, which means on the average
the server needs only one step to select a chunk.</p>

<p>So, for every chunk the following steps are done, until we find a fitting
chunk:</p>

<ul>
<li>First, any <a href="#item_issued"><code>ISSUED</code></a> chunk is converted to <a href="#item_tobedone"><code>TOBEDONE</code></a> when it is found to be
too old.  This ensures that <a href="#item_failed"><code>FAILED</code></a> chunks, or chunks that were
never returned by the client, or in the VERIFY state too long, will be given
out again.



<li>If the current chunk has not the <a href="#item_tobedone"><code>TOBEDONE</code></a> status, skip it.



<li>Otherwise, mark the chunk as likely candidate and proceed to next step.



<li>check if the size of the chunk is not too big for the client. If the size is
in the limits (around 2 times the size of what the client requested), abort
the search (this causes this chunk to be issued to the client).

</ul>

<p>After this loop, we are garantueed to come out with either:</p>

<ol>
<li><strong><a name="item_big">a chunk too big (missfitting chunk)</a></strong><br />
</li>
<li><strong><a name="item_a_fitting_chunk">a fitting chunk</a></strong><br />
</li>
<li><strong><a name="item_no_chunk_at_all">no chunk at all</a></strong><br />
</li>
</ol>

<p>In the first case, the chunk is split into two pieces, and the first piece
is given to the client.</p>

<p>In case 2 the chunk is given ``as it is'' to the client.</p>

<p>In the last case, the job does no longer contain any <a href="#item_tobedone"><code>TOBEDONE</code></a> chunks. If
it also does not contain <a href="#item_failed"><code>FAILED</code></a>, <code>VERIF</code> or <a href="#item_issued"><code>ISSUED</code></a> chunks, it can be
closed. The server will then try another job to find some work for the client.</p>



</div>

<h2><a name="calculating_the_chunk_size">CALCULATING THE CHUNK SIZE</a></h2>

<div class="text">

<p>To determine whether a given chunk is suitable or not, the server must know the
desired chunksize of the client. This value is given in minutes to the server,
so calculating the size of the chunk in keys (or passwords etc) is neccessary.</p>

<p>Formerly, this was a complicated process involving some guesswork, but with
Math::String it is very easy.</p>

<p>We first take the client's current speed value for the job in question.</p>

<p>If this value does not yet exist, we take the client's average speed ratio
and multiply it with the current jobtype's speed, to account for different
speeds of different job types, f.i. any job is probably faster than the test
job.</p>

<p>The reason why to have a speed value for each job rather than only for each
job type is that clients can differ on a per job basis greatly (some clients
are suited to certain jobs, others to different ones) and also each job of a
job type can differ, based on the target information.</p>

<p>The result is the rough number of keys per second a client can make for 
exactly this job.</p>

<p>After multiplying this speed value by 60 and the desired size of the chunk in
minutes, we get a grand total of keys the client would like to get.</p>

<p>This can be compared directly to the chunksizes in the chunklist. If no
suitable chunk is found, we can simple add this number to the start key of
the biggest chunk and split this chunk there, obtaining an chunk exactly as
big as the client wanted.</p>

<p>Formerly, the chunk borders were somewhat limited by having the some (mostly
the last three) chars fixed, this is taken into account upon splitting a
chunk. Nowadays, chunk borders can be anything and anywhere.</p>

<p>This limitation has historically reasons, and can be adjusted for each jobtype
to match the implementation of the worker.</p>

<p>Each chunk also has a minimum size, and this is usually the charset's count of
characters. This is the same as having the last char fixed, and was implemented
to avoid chunks with a size too small, e.g. a size of 1.</p>



</div>

<h3><a name="mismatching_size">Mismatching Size</a></h3>

<div class="text">

<p>The resulting chunk will not fit exactly the client's need. This is no direct
problem as long as the size fit's roughly with a factor between 0.1 and 5.</p>

<p>When the client finally delivers the result of the chunk, it also tells the
server how many seconds it took. From this number and the real chunk size
the server can calculate how many keys per second the client really did
and save this as the new speed value of the client.</p>

<p>The change to the client's speed value is limited to be between 0.5 and 2, to
avoid miscalculations wrecking havoc.</p>

<p>Upon the next connect the client will get a much better fitting chunk and the
chunksizes will always be adjusted dynamically to the client's speed.</p>

<p>Therefore, changing the client's hardware, having background processes etc
should all be completely transparent to the user and administrator of the
server and client.</p>



</div>

<h2><a name="reading_flushing">READING/FLUSHING</a></h2>

<div class="text">

<p><code>dicopd</code> is a real daemon, it only needs to read the data upon start, and
then can hold it in memory all the time.</p>

<p>The data is only flushed to disk when it is modified. To further optimize this
and save time and stress on the external storage media, the flush is only
executed after a certain (configurable) time has elapsed.</p>

<p>The advantage is that status requests do never flush the data (they don't
modify it), and all others do so infrequently that the hard disk is not
stressed.</p>

<p>A disadvantage is that SUCCESS events (finding a result) will only be emailed
and land in the log, but not result in a data-base sync. Upon finding a 
result, an extra <code>flush()</code> is issued to correct this.</p>



</div>

<h2><a name="client_data">CLIENT DATA</a></h2>

<div class="text">

<p>Certain data is held for each client, like it's speed, id, name etc.</p>



</div>

<h3><a name="failure_counter">Failure counter</a></h3>

<div class="text">

<p>Each client has a list of failure counters. The list contains two entries for
each jobtype, denoting the time of the last failure and a counter.</p>

<p>The counter is reset to zero when a client passes a testcase for this jobtype.
It is incremented by three if a testcase for this jobtype fails, and
incremented by one if the client fails a chunk.</p>

<p>Whenever the counter is increased, the time is noted.</p>

<p>When the counter is greater than three, the client will get no more work for
jobs of the same jobtype until the counter is reset.</p>



</div>

<h2><a name="proxy_list">PROXY LIST</a></h2>

<div class="text">

<p>The server also contains a list of proxies. These are kept separate from
clients because they play a special role. Technical proxy connects are treated
like client connects, with a few extra twists. The reason is that proxies
request work/files/tests and deliver results on behalf of other clients - they
never do any work by themselves.</p>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.</p>



</div>


