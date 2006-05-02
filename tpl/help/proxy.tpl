

<h1><a href="##selfhelp_list##">DiCoP Help</a> - Proxy</h1>

<!-- topic: The internal details of a server acting as a proxy. -->

<div class="text">

<p>
The internal details of a server acting as a proxy.
</p>

<ul>

	<li><a href="#item_name">NAME</a></li>
	<li><a href="#item_overview">OVERVIEW</a></li>
	<li><a href="#item_proxy__client_connect">PROXY - CLIENT CONNECT</a></li>
	<li><a href="#item_different_request_types">DIFFERENT REQUEST TYPES</a></li>
	<ul>

		<li><a href="#item_administrative_messages">ADMINISTRATIVE MESSAGES</a></li>
		<li><a href="#item_access_restrictions">ACCESS RESTRICTIONS</a></li>
	</ul>

	<li><a href="#item_ensuring_data_integrity">ENSURING DATA INTEGRITY</a></li>
	<li><a href="#item_performance">PERFORMANCE</a></li>
	<ul>

		<li><a href="#item_maximum_possible_clients">Maximum possible clients</a></li>
		<li><a href="#item_network_performance">Network performance</a></li>
	</ul>

	<li><a href="#item_author">AUTHOR</a></li>
</ul>



<p>Last update: 2004-01-15</p>

</div>



<h2><a name="overview">OVERVIEW</a></h2>

<div class="text">

<p>The typical server setup looks like this:
</p>

<pre>

                                +--------+
                                | Server |
                                +--------+
                                    |
      +------------+-----------+----+--------------------+
      |            |           |                         |
  +--------+  +--------+  +--------+                 +--------+
  | Client |  | Client |  | Client |                 | Proxy  |  
  +--------+  +--------+  +--------+                 +--------+
                                                         |
                                             +-----------+------------+
                                             |           |            |
                                         +--------+  +--------+  +--------+ 
                                         | Client |  | Client |  | Client |
                                         +--------+  +--------+  +--------+</pre>

<p>In this case we focus on the proxy part, although the same software is used
for a proxy as for a server. The only differences are:</p>

<ul>
<li>inside <code>server.cfg</code> the setting <code>is_proxy</code> is set to on, and thus <code>proxy.cfg</code> is also read and used.



<li>Instead of <code>dicopd</code> you use <code>dicopp</code> to start the proxy

</ul>

<p>The first sections in <em>Dicop.pod</em> also apply.</p>

<p>The main reasons for deploying a proxy are:</p>

<dl>
<dt><strong><a name="item_reducing_the_load_on_the_main_server">Reducing the load on the main server</a></strong><br />
</dt>
<dd>
Due to caching the load on the main server is reduced. Also, DOS (or other)
attacks on the proxy will not effect the main server, thus protecting it.
</dd>



<dt><strong><a name="item_restricting_access">Restricting access</a></strong><br />
</dt>
<dd>
You can restrict access to the proxy more tightly, thus disallowing normal
clients from viewing any status page, and restricting the administration at
the main server to only certain clients.
</dd>

</dl>

<p>Currently the proxy can only be connected by normal clients, not by other
proxies in itself. So you can not chain proxies together. This will probably
resolved some time in the future.</p>

<p>There are two things that reduce the load on the main server:</p>

<dl>
<dt><strong><a name="item_less_requests">less requests</a></strong><br />
</dt>
<dd>
For instance, requests for file URLs can be served by the proxy independently.
</dd>
<dd>

<p>In other cases, the result of some connect can be cached and on subsequent
client requests re-send to the client. For instance a request for test-cases
will be answered from the cache, and only from time to time the proxy needs
to contact the server for the actual list of test cases.</p>

</dd>



<dt><strong><a name="item_less_connects">less connects</a></strong><br />
</dt>
<dd>
Each connect has a certain overhead, no matter how many requests the client
sends to the server per connect. By serving certain requests locally the
proxy eliminates the need to connect the server.
</dd>
<dd>

<p>By eliminating the number of requests send to the server, it is also possible
to eliminate the need for some connects entirely. Especially if there is only
one request (like a request for a file or a test case), the connect to the
server is not neccessary.</p>

</dd>
<dd>

<p>In other cases, it is possible to delay sending requests to the server,
group them together and only send them together. By sending, for instance,
16 requests with each connect, instead of two or three, the number of connects
is reduced and the same number of requests causes less CPU overhead on the
server.</p>

</dd>

</dl>



</div>

<h2><a name="proxy__client_connect">PROXY - CLIENT CONNECT</a></h2>

<div class="text">

<p>Upon a connect from a client, the proxy  does the following:</p>

<pre>
        check if the request format is ok
        check if client/proxy is valid (and allowed) and authentication is ok
        if anything is ok, look for status request
        if client is a proxy: error

        status request and other requests together: error
        status request and no other requests: 
          deliver status if client is allowed to view it, be done

        cache all report requests, and generate (dummy) responses for them
        answer all requests for work and testcases from the cache
          if cache is empty, talk to upstream server and get new work
        if a report with a success status comes in, report it back to server
        send back all responses to client in one go</pre>



</div>

<h2><a name="different_request_types">DIFFERENT REQUEST TYPES</a></h2>

<div class="text">

<p>Depending on the request type of the client, the proxy does different things.</p>

<dl>
<dt><strong><a name="item_back">report work/testcases back (DONE)</a></strong><br />
</dt>
<dd>
These report will be answered with a dummy answer (basically: ``Thanx!'') and
sorted into the send cache.
</dd>



<dt><strong>report work/testcases back (SOLVED)</strong><br />
</dt>
<dd>
These report will be answered with a dummy answer (basically: ``Thanx!'') and
sorted into the send cache. Then a talk to the server is scheduled to happen
as soon as possible (aka: before the next client connects, so that it can run
between the two client connects)
</dd>



<dt><strong>report work/testcases back (FAILED)</strong><br />
</dt>
<dd>
These report will be answered with a dummy answer (basically: ``Oups!'') and
will be marked in the chunk cache as failed. Failed chunks will be given
to the next client after a certain time frame. If a chunk fails more than one
time, it can get too old and dies (is removed from the chunk cache). This
is to prevent the proxy from handing out stale work that is handed out by the
server to another client/proxy.
</dd>



<dt><strong><a name="item_request_work">request work</a></strong><br />
</dt>
<dd>
When a client requests work, the proxy looks into it's chunk cache to see if
a fitting chunk is available. If yes, this is handed out to the client.
Otherwise, the send cache is sent to the server, and simultanously the chunk
cache is filled with chunks from the server. If there is still no chunk for
the client, or the client is denied by the server, an error is sent back to
the client. Otherwise the requested work are sent back.
</dd>



<dt><strong><a name="item_request_testcase">request testcase</a></strong><br />
</dt>
<dd>
The testcases are cached and sent back to the client from this cache. The
testcase cache is invalidated every now and then (default: 24 hours) and
the next time the talk to the server occurs, the testcase cache is refilled
with the newest list of testcases.
</dd>

</dl>



</div>

<h3><a name="administrative_messages">ADMINISTRATIVE MESSAGES</a></h3>

<div class="text">

<p>The server and proxy will exchange messages for administrative purposes. For
instance the server might tell the proxy that one job got closed, and thus the
proxy must purge all chunks in his chunk cache for that particulary job.</p>



</div>

<h3><a name="access_restrictions">ACCESS RESTRICTIONS</a></h3>

<div class="text">

<p>The proxy will for security reasons disallow automatically all requests that
have a <code>cmd</code> of the following:</p>

<pre>
        add             add something
        confirm         confirm deletions
        change          change something
        del             delete something
        form            status form requests</pre>



</div>

<h2><a name="ensuring_data_integrity">ENSURING DATA INTEGRITY</a></h2>

<div class="text">

<p>All the data is stored at the server, and a proxy has only temporary caches.
Thus the proxy never writes any data back to disk, and there is no need to
backup anything.</p>

<p>In the event of a system crash or when the proxy process dies, the temporary
data will be lost. Since the proxy reports back to a server in regular
intervalls, only some data for the last hour (or so) will be lost. This will
be handled transparently by the server and should occur so seldom that it won't
impact performance (much).</p>



</div>

<h2><a name="performance">PERFORMANCE</a></h2>

<div class="text">

<p>The proxy should have roughly the same performance than a server.</p>

<p>It is not yet sure how much of the data transfer and thus request-handling
time at the server a proxy will save.</p>

<p>Requests for testcases are seldom, but if you have 30 clienst restarted each
day, you save 29 requests for testcases at the main server. A more important
role play the savings trough caching the requests/reports for work, and with
a setting of caching 4 chunks for each client connect, it is envisioned that
a proxy could save about 50% of all connects to the server. It is still
unclear  how much time this will save, though, since eventually the same
number of requests must be made to the server, only that they are then more
compact (e.g. more requests per connect simultanously).</p>



</div>

<h3><a name="maximum_possible_clients">Maximum possible clients</a></h3>

<div class="text">

<p>The proxy should be able to handle roughly the same number of clients than
the server, if both have equivalent hardware. So with a load of about 25% the
following machines will be able to handle roughly:</p>

<ol>
<li><strong><a name="item_mhz_amd_k_2d6">Mhz AMD K-6</a></strong><br />
</li>
300 clients



<li><strong><a name="item_piii">MHz PIII (mobile)</a></strong><br />
</li>
20000 clients



<li><strong><a name="item_athlon">1 GHz AMD Athlon (TBred)</a></strong><br />
</li>
60000 clients (estimated)

</ol>

<p>The numbers are per hour and derived from a benchmark done in August 2002
under DiCoP v2.20 and Perl v5.8.0.</p>

<p>If your clients connect the server twice per hour, halve the values, if they
connect every other hour, double them.</p>



</div>

<h3><a name="network_performance">Network performance</a></h3>

<div class="text">

<p>Since the proxy caches things, the network traffic to the server should also
be reduced. But since only a few bits are exchanged anyway, this will probably
not have much impact.</p>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.</p>



</div>


