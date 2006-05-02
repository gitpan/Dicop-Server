

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Dicop</h1>

<!-- topic: Overview and the communication between server, proxy, client and worker in depth. -->

<div class="text">

<p>
Overview and the communication between server, proxy, client and worker in depth.
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#overview">OVERVIEW</a></li>
	<ul>

		<li><a href="#general_layout">General layout</a></li>
		<li><a href="#with_fileserver">With fileserver</a></li>
		<li><a href="#layout_of_services">Layout of services</a></li>
		<li><a href="#smp_machines_and_hyperthreading">SMP Machines and Hyperthreading</a></li>
		<li><a href="#network_mounting_vs__local_copy">Network Mounting vs. Local Copy</a></li>
		<li><a href="#connections_and_protocols">Connections and protocols</a></li>
		<li><a href="#ssl_support">SSL Support</a></li>
	</ul>

	<li><a href="#using_different_protocols">USING DIFFERENT PROTOCOLS</a></li>
	<li><a href="#cgibin_vs__daemon">CGI-BIN vs. DAEMON</a></li>
	<li><a href="#load_balancing">LOAD BALANCING</a></li>
	<li><a href="#server">SERVER</a></li>
	<li><a href="#proxy">PROXY</a></li>
	<li><a href="#client">CLIENT</a></li>
	<ul>

		<li><a href="#updating_works_and_other_files">Updating works and other files</a></li>
	</ul>

	<li><a href="#worker">WORKER</a></li>
	<li><a href="#communication_between_server__proxy_and_client">COMMUNICATION BETWEEN SERVER, PROXY AND CLIENT</a></li>
	<ul>

		<li><a href="#output">Output</a></li>
		<li><a href="#complete_parameter_structure">Complete parameter structure</a></li>
		<li><a href="#sending_info_to_the_server">Sending info to the server</a></li>
		<li><a href="#further_examples">Further Examples</a></li>
		<li><a href="#reporting_back_results">Reporting back results</a></li>
		<li><a href="#requesting_test_cases">Requesting test cases</a></li>
		<li><a href="#requesting_more_work">Requesting more work</a></li>
		<li><a href="#requesting_files__autoupdating_">Requesting files (auto-updating)</a></li>
		<li><a href="#requesting_status_pages">Requesting status pages</a></li>
		<li><a href="#requesting_help_pages">Requesting Help Pages</a></li>
		<li><a href="#requesting_forms">Requesting Forms</a></li>
		<li><a href="#adding_a_job">Adding a job</a></li>
		<li><a href="#adding_other_objects">Adding other objects</a></li>
		<li><a href="#deleting_objects">Deleting Objects</a></li>
		<li><a href="#changig_a_job_chunk">Changig a job/chunk</a></li>
		<li><a href="#a_chunk_of_work">A chunk of work</a></li>
		<li><a href="#a_testcase">A testcase</a></li>
		<li><a href="#clienthandling_of_server_responses">Client-handling of server responses</a></li>
		<li><a href="#example">Example</a></li>
	</ul>

	<li><a href="#target_file_vs__target_hash">TARGET FILE VS. TARGET HASH</a></li>
	<li><a href="#ensuring_data_integrity">ENSURING DATA INTEGRITY</a></li>
	<li><a href="#perfromance">PERFROMANCE</a></li>
	<ul>

		<li><a href="#old_model__dicop_v1_x_and_server_v2_x_">Old model (dicop v1.x and server v2.x)</a></li>
		<li><a href="#new_model__dicopd_v2_x_">New model (dicopd v2.x)</a></li>
		<li><a href="#speed_of_server_vs__dicopd">Speed of server vs. dicopd</a></li>
		<li><a href="#maximum_possible_clients__2001_">Maximum possible clients (2001)</a></li>
		<li><a href="#performance_status_update__2002_">Performance status update (2002)</a></li>
		<li><a href="#performance_status_update__summer_2003_">Performance status update (Summer 2003)</a></li>
		<li><a href="#performance_status_update__fall_2003_">Performance status update (Fall 2003)</a></li>
		<li><a href="#network_performance__2001_">Network performance (2001)</a></li>
		<li><a href="#network_performance__update_2003_">Network performance (update 2003)</a></li>
	</ul>

	<li><a href="#todo">TODO</a></li>
	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>Last update: 2004-12-22</p>

</div>



<h2><a name="overview">OVERVIEW</a></h2>

<div class="text">



</div>

<h3><a name="general_layout">General layout</a></h3>

<div class="text">

<p>The typical cluster setup looks like this:</p>

<pre>
                                +--------+
                                | Server |
                                +--------+
                                    |
      +------------+-----------+----+--------------------+
      |            |           |                         |
  +--------+  +--------+  +---------+             +--------------+
  | Client |  | Client |  | Browser |             | Dicop::Proxy |
  +--------+  +--------+  +---------+             +--------------+
                                                         |
                                             +-----------+------------+
                                             |           |            |
                                         +--------+  +--------+  +--------+
                                         | Client |  | Client |  | Client |
                                         +--------+  +--------+  +--------+</pre>

<p>In the picture above, each box represents one seperate machine. It is possible
to run the client on the same machine as the server - although this should
be done for testing purposes only.</p>

<p>The machine denoted with <code>Browser</code> is used to configure the server, although
it would also possible to run a client on it.</p>



</div>

<h3><a name="with_fileserver">With fileserver</a></h3>

<div class="text">

<p>Usually you want also to have a fileserver, that can serve updated workers and
target files for jobs. This can be just a service (think Apache) on the same
box, or an entirely different machine. It is easier to have the fileserver
serving the same physical files from the server, though.</p>

<pre>
                                +--------+-------------+
                                | Server | File server |
                                +--------+-------------+
                                    |             |
                                    |             +-------------------+
                                    |             |                   |
      +------------+-----------+----+-------------:------+            |
      |            |           |                  |      |            |
      |            |           |                  |      |            |
      +------------+-----------+------------------+      |            |
      |            |           |                         |            |
  +--------+  +--------+  +--------+            +--------------+ +------------+
  | Client |  | Client |  | Client |            | Dicop::Proxy | | HTTP proxy | 
  +--------+  +--------+  +--------+            +--------------+ +------------+
                                                         |            |
                                             +-----------+------------+
                                             |           |            |
                                         +--------+  +--------+  +--------+ 
                                         | Client |  | Client |  | Client |
                                         +--------+  +--------+  +--------+</pre>

<p>Since the fileserver is usually an HTTP server (but FTP would work, too), you
can set up a normal HTTP proxy between the clients and the fileserver, if you
want.</p>

<p>The clients are asking the server for the location (URL) of the files to
download. The clients behind the proxy could be told by the dicop proxy a
different URL, so that they automatically use the HTTP proxy, or use a different
fileserver altogether.</p>

<p>Please see <a href="#requesting_files__autoupdating_">REQUESTING FILES (AUTO-UPDATING)</a>.</p>



</div>

<h3><a name="layout_of_services">Layout of services</a></h3>

<div class="text">

<p>The next picture details the machines and the ``services'' that are running at
them. For simplicity, proxies have been left out.</p>

<p>The following picture assumes that the client is stored locally at each node.
Workers need not be stored locally at client startup, but will be downloaded
automatically by the client from file server. Each client has multiple
workers, one for each jobtype. Only one worker is active (*) at a time:</p>

<pre>
                             +--------+-------------+
                             | Server | File server |
                             +--------+-------------+
                                      ^             
                                      |            
                       +--------------+-------------+
                       |              |             |             
                       |              |             |            
                       v              v             v
                  +---------+    +--------+    +---------+
                  | Client  |    | Client  |   | Client  |      
                  +---------+    +---------+   +---------+ 
                  | Worker* |    | Worker  |   | Worker* |
                  +---------+    +---------+   +---------+
                  | Worker  |    | Worker* |    
                  +---------+    +---------+</pre>

<p>Note: It is also possible to run the fileserver on a seperate machine.</p>



</div>

<h3><a name="smp_machines_and_hyperthreading">SMP Machines and Hyperthreading</a></h3>

<div class="text">

<p>The client and worker only takes advantages of one physical CPU. If you have
a machine with two (or more) physical or virtual (hyperthreading) CPU cores,
you can simple start two or more clients on the same machine.</p>

<p>These will each start a worker on their own, and each of these workers will
be using one CPU core. Of course, you need a good OS that keeps each process
on one CPU instead of switching them around.</p>

<p>Starting two clients on a machine with only one CPU will probably de-
instead of increasing performance.</p>

<p>The following picture depicts a SMP machine with two CPUs and a single
CPU machine. Only one worker is active (*) at a time:</p>

<pre>
                             +--------+-------------+
                             | Server | File server |
                             +--------+-------------+
                                      ^             
                                      |            
                              +-------+---------------+
                              |                       |           
                              |                       | 
                              v                       v 
                +---------------------------+  +-------------+
                | +---------+   +---------+ |  | +---------+ |
                | | Client  |   | Client  | |  | | Client  | |
                | +---------+   +---------+ |  | +---------+ |
                | | Worker* |   | Worker  | |  | | Worker* | |
                | +---------+   +---------+ |  | +---------+ |
                | | Worker  |   | Worker* | |  | | Worker  | |
                | +---------+   +---------+ |  | +---------+ |
                +---------------------------+  +-------------+
 
Note: It is also possible to run the fileserver on a seperate machine.</pre>



</div>

<h3><a name="network_mounting_vs__local_copy">Network Mounting vs. Local Copy</a></h3>

<div class="text">

<p>The following picture assumes that the client and the workers are on a mounted
NFS/Samba directory. Since the workers are also in the mounted directory, there
is no need to download them. The same goes for target files, so in this case
you can skip the file server. The worker is still <em>running</em> locally at the
client, though:</p>

<pre>
                       +--------+-----+-------+
                       | Server | NFS | Samba |
                       +--------+-----+-------+
                                      |             
                                      |            
                       +--------------+-------------+
                       |              |             |             
                       |              |             |            
                       |              |             |
                  +--------+     +--------+    +--------+
                  | Client |     | Client |    | Client |       
                  +--------+     +--------+    +--------+ 
                  | Worker |     | Worker |    | Worker |       
                  +--------+     +--------+    +--------+
                  | Worker |
                  +--------+</pre>



</div>

<h3><a name="connections_and_protocols">Connections and protocols</a></h3>

<div class="text">

<p>Currently the HTTP protocol is used to exchange data between server/proxy and
client. This was just for simplicity, any protocol could be used, even email.</p>

<p>The connections from server to client/proxy and proxy to client are <em>not</em>
permanent/persistent, they are only established when transmitting information.</p>

<p>Only the clients establishes a connection to the server (or proxy), and only
the proxy establishes a connection to the server. The server (or proxy) never
starts talking to any client or proxy.</p>

<p>Each server/proxy/client handles only one connection from a client/proxy
at a time. Each connection from a client to a server/proxy can carry more
than one message (these messages are always called ``request'', even though they
might ``report'' some data back), and the server/proxy will answer all requests
right away, e.g. usually no answers are delayed to the next connection.</p>

<p>(Proxies might delay an answer by answering first ``Wait, no work for you.''
and then giving the ``real'' answer on the next connect attempt. However, the
client does not need to handle this in any special way.)</p>

<p>There is only one main server. To reduce the load on it there can be an
unlimited number of proxies. The proxies cache certain requests and then
bundle them into one big request to the server, this minimizes the time to
handle each request. (Note: Proxies are not working yet)</p>



</div>

<h3><a name="ssl_support">SSL Support</a></h3>

<div class="text">

<p>Server, proxy and client now have the ability to support the SSL protocol via
the <code>proto = &quot;ssl&quot;</code> setting in the config file. Together with updated clients
this allows all communication between server and client to be encrypted.</p>

<p>However, at the moment the server can only be either <code>ssl</code> or <code>tcp</code>,
as indicated by the <code>proto = &quot;foo&quot;</code> setting in the config, e.g. you cannot
mix SSL and non-SSL clients (this is a limitation of <code>Net::Server</code>, and
currently there is no way to overcome this without rewriting a lot of
third-party code from scratch).</p>

<p>This means that if you switch a server to SSL, <strong>all</strong> clients connecting to
that server must also support SSL.</p>

<p>To overcome this limitation, use your server with <code>proto = &quot;tcp&quot;</code> and then
add a proxy to it. Run then a <code>Dicop::Proxy</code> at the same machine (or another
machine if desired), and switch that proxy to SSL and point it to your main
server as it's upstream server.</p>

<p>All clients that support SSL must then connect via that proxy, while all
others must use the server directly. Here is a picture showing the setup:</p>

<pre>
        +---------------|   TCP  +---------------+
        | Server (tcp)  |&lt;-------| Proxy (ssl)   |
        +---------------|        +---------------+
                ^                       ^
                | TCP                   | SSL
                |                       |
        +---------------+        +---------------+
        | Client (tcp)  |        | Client (ssl)  |
        +---------------+        +---------------+</pre>

<p>Note that the connection to the file server is independend of the connection
to the server/proxy. Clients that support SSL can either use <code>http</code>, <code>ftp</code>
or <code>https</code>, while clients without SSL support can only use <code>http</code> or <code>ftp</code>
file server. In a mixed-client environment, it is best to use a non-ssl
fileserver.</p>

<pre>
        +---------------+   TCP  +--------------+
        | Server (tcp)  |&lt;-------| Proxy (ssl)  |
        +---------------+        +--------------+
                ^                       ^
                | TCP                   | SSL
                |                       |
        +---------------+        +--------------+
        | Client (tcp)  |        | Client (ssl) |
        +---------------+        +--------------+
                |                       |
                |                       |
                |                       v
                |             +-------------------+
                |------------&gt;| Fileserver (http) |
                              +-------------------+</pre>

<p>However, clients that go over the proxy can have an independend file server,
so you could use a setup like:</p>

<pre>
        +---------------+   TCP    +---------------+
        | Server (tcp)  |&lt;---------|  Proxy (ssl)  |
        +---------------+          +---------------+
                ^                         ^
                | TCP                     | SSL
                |                         |
        +---------------+          +---------------+
        | Client (tcp)  |          | Client (ssl)  |
        +---------------+          +---------------+
                |                         |
                |                         |
                |                         v
        +-------------------+ +--------------------+
        | Fileserver (http) | | Fileserver (https) |
        +-------------------+ +--------------------+</pre>



</div>

<h2><a name="using_different_protocols">USING DIFFERENT PROTOCOLS</a></h2>

<div class="text">

<p>It would be possible (and trivial) to write a simple proxy server, which f.i.
accepts email as input, parses it, and then sends the request to the server.
After receiving the answer, it emails back the answer to the original sender.
This would allow off-line clients, that do not require a direct net connection
to the server.</p>



</div>

<h2><a name="cgibin_vs__daemon">CGI-BIN vs. DAEMON</a></h2>

<div class="text">

<p>The main server runs as daemon <code>dicopd</code>. The other way, running it as
cgi-bin script, is no longer possible.</p>

<p><code>dicopd</code> has the advantage that the script is already compiled in memory,
and anly needs to parse the request. Only from time to time the modified data
will be written back to the disk - this makes it much faster than the old way.</p>



</div>

<h2><a name="load_balancing">LOAD BALANCING</a></h2>

<div class="text">

<p>To minize the load, it is possible to setup more than one proxy:</p>

<pre>
                                +--------+
                                | Server |
                                +--------+
                                    |
      +------------+------------+---+--------------------+
      |            |            |                        |
  +--------+  +--------+   +--------------+      +--------------+
  | Client |  | Client |   | Dicop::Proxy |      | Dicop::Proxy |  
  +--------+  +--------+   +--------------+      +--------------+
                                |                        |
                                |            +-----------+------------+
                                |            |           |            |
                                |        +--------+  +--------+  +--------+ 
                                |        | Client |  | Client |  | Client |
                                |        +--------+  +--------+  +--------+
                                |
                     +----------+------------+
                     |          |            |
                +--------+  +--------+  +--------+ 
                | Client |  | Client |  | Client |
                +--------+  +--------+  +--------+</pre>

<p>The clients are not required to use a specific proxy, in fact they can use
the main server directly, or any proxy as long all the proxies belong to the
same main server:</p>

<pre>
                                +--------+
                                | Server |
                                +--------+
                                  .  .  .
                             ......  .  ......
                             .       .       .
                         +--------+  .  +--------+
                         | Proxy  |  .  | Proxy  |  
                         +--------+  .  +--------+
                             .       .       .
                             ......  .  ......
                                  .  .  .
                                +--------+
                                | Client |
                                +--------+</pre>

<p>Note that the connections above are not simultanously, but occur independendly
from each other and one after one.</p>

<p>It is possible to have the client support two or more independend main servers,
f.i. if you want you client to compute on two different projects or balance
the load on the main servers further.</p>

<p>Note that jobs between the two servers can not be shared, but each server could
run it's own set of jobs and clients would work on both projects.</p>

<p>The client would need, of course, a way to specify how to distribute it's
working power between the projects, currently it would give each main server
the same amount of CPU time:</p>

<pre>
                +-----------+                      +----------+
                | Server 1  |                      | Server 2 |  
                +-----------+                      +----------+
                      |                                 |
                      |                                 |
                 +---------+                        +--------+
                 | Proxy 1 |                        | Proxy2 |  
                 +---------+                        +--------+
                      |                               ^ |
                      |             ..................| |
                      |             .                   |
         +------------+----------+  .            +-------------+
         |            |          |  |            |             |
   +----------+  +----------+  +----------+ +----------+  +----------+
   | Client 1 |  | Client 2 |  | Client 3 | | Client 4 |  | Client 5 |
   +----------+  +----------+  +----------+ +----------+  +----------+</pre>

<p>Here client 3 connects to two proxies.</p>

<p>Note: This does currently not work since the client needs to remember from
which proxy it got which chunk so that it can report the result back to the
appropriate proxy.</p>

<p>This should be of course fault tolerant, so that if proxy 1 goes down,
the client can try to get the result back to proxy 2, 3 and so on, until it
find one proxy which accepts the result because it is on the same server
than the original proxy 1.</p>

<p>One could of course imagine that certain proxies know about the
two main servers and automatically route the client's report to the
right server.</p>



</div>

<h2><a name="server">SERVER</a></h2>

<div class="text">

<p>Upon a connect from a client, the (main) server does roughly the following:</p>

<pre>
        check if the request format is ok
        check if client/proxy is valid and authentication info ok
        if anything is ok, look for status request

        status request and other requests together? yes =&gt; error
        status request and no other requests: deliver status page, be done

        if info requests &amp; client is NOT a proxy: error
        check in all info requests 
        try to check in any report-request and generate responses for them
        try to generate responses for all work/test requests
        send back all responses in one go
 
See also: I&lt;Client&gt; and I&lt;Proxy&gt;.</pre>



</div>

<h2><a name="proxy">PROXY</a></h2>

<div class="text">

<p>A <code>Dicop::Proxy</code> is just a special server/client combo. It acts as a server
to the clients that connect to it, and is completely transparent to them, e.g.
the client does not care or know whether it connects to a proxy (or even
a certain proxy) or the main server.</p>

<p>On the other side the proxy acts like a normal client to the server, except
that all it's connects are on behalf of other clients.</p>

<p>A <code>Dicop::Proxy</code> does never do any work by itself, this is enforced by the
server.</p>

<p>The goal of a <code>Dicop::Proxy</code> is to minimize the amount of connections done
by clients to the server (server load), and yet to be able to have the same
real-time stats on the server.</p>

<p>Download the Dicop::Proxy package on our website to install a Dicop proxy.</p>



</div>

<h2><a name="client">CLIENT</a></h2>

<div class="text">

<p>A client requests work (and testcases) from the server, and then determines
what worker it has to use to do the work.</p>

<p>If necessary, the client will update the workers and needed files by
downloading them from the fileserver. To discover the download location,
the client will ask the <em>SERVER</em>.</p>

<p>The workers are seperate programs that are started by the client, process the
chunk of work, and print out the result.</p>

<p>The result is then send back by the client to the server.</p>

<p>See also: <em>WORKER</em> and <em>SERVER</em>.</p>



</div>

<h3><a name="updating_works_and_other_files">Updating works and other files</a></h3>

<div class="text">

<p>See also <a href="#a_chunk_of_work">A CHUNK OF WORK</a> for details on what the server
sends to the client on work or test requests.</p>

<p>Basically, the files needed to work on a chunk fall into three categories:</p>

<dl>
<dt><strong><a name="item_the_worker_itself">The worker itself</a></strong><br />
</dt>
<dd>
The worker program to do the actual work. The server sends a hash as the
<code>hash</code> field in the answer to any work or test request. The client needs to
make sure that each worker for each request has the same hash, and if not,
update it.
</dd>



<dt><strong><a name="item_target_files">target files</a></strong><br />
</dt>
<dd>
Some chunks only have a hash value as a target, meaning the worker checks
the keyspace of the chunk against this hash value. If the worker needs more
than a few bytes to check each key, then a target file is used instead.
</dd>
<dd>

<p>See <a href="#target_file_vs__target_hash">TARGET FILE VS. TARGET HASH</a> for more informtation.</p>

</dd>



<dt><strong><a name="item_additional_files">additional files</a></strong><br />
</dt>
<dd>
These might be the charset description file <code>charsets.def</code>, dictionary files,
additional libraries needed by the worker, or any other arbitrary file that is
needed to work on a chunk. These files will be hashed by the server and the
hash along with the filename is sent to the client to force it to download
these files.
</dd>

</dl>



</div>

<h2><a name="worker">WORKER</a></h2>

<div class="text">

<p>A worker is a stand-alone program that can process on chunk of the keyspace.
The chunksize is variable, and the worker does not need to care about anything
else than working the chunk.</p>

<p>The worker receives the input on the commandline, and prints out it's findings.</p>



</div>

<h2><a name="communication_between_server__proxy_and_client">COMMUNICATION BETWEEN SERVER, PROXY AND CLIENT</a></h2>

<div class="text">

<p>All communication runs currently over the HTTP protocoll.</p>

<p>Note that there is no such a thing as a ``client'' or ``server'' per se. A client
can be another server or proxy. The client here is taken as the one initiating
the connection and sending something to the other partner, which is said to be
the server and answers. In praxis, client nodes only connect a server or proxy,
and only proxies connect to another server.</p>

<p>In the DiCoP environment, messages passed between the client, server and proxy
are called <em>Request</em>.</p>

<p>The client sends <code>request(s)</code> to the server, and the server responds with it's
answer(s). The requests are formed by sending parameters (in GET or POST
style). The parameter names are <strong>req0001</strong>, <strong>req0002</strong> and their value is the
actual request. This means each connect of a client can carry multiple
requests, f.i. the client can report back a result and request more work
at the same time.</p>

<p>The servers answers are also <em>requests</em>, even though the name is a bit
misleading and you should think of them as <em>answers</em>. But they follow the
same format and are represented by the same code/objects internally.</p>

<p>The request number must be in the range <code>0001..9999</code>, e.g. the client should
<strong>never send req0000</strong> to the server. <code>req0000</code> is reserved for general
answers from the server to the client, e.g. global error messages. A
<code>req0000</code> always applies to the entire connect, while any other request
number only applies to the same request send by the client.</p>

<p>Each request has a set of parameters and their value, which are separated by
a ``<strong>_</strong>''. ``_'' is used to distinguish it from ``='' which is used in GET style
requests. The parameters are separeted by using ``<strong>;</strong>''.</p>

<p>F.i. ``blah_foo;name_boo,boh,bah;type_9'' would be a set of 3 parameters 
(blah, name and type) with their values (foo, [ boo, boh, bah] and 9).
Special chars must be encoded (with the %XX style, where XX is the ASCII code
of the character) to protect from special chars like ``;'' or ``='' that confuse the
parser.</p>

<p>The POST method is prefered, since URLs have a maximum length limit, but GET
style requests work as well. The client usually uses POST, while a browser
would use GET.</p>

<p>The parameter <strong>cmd</strong> is required and specifies the type of the request as
follows:</p>

<pre>
        cmd     add             add a job/client/charset/jobtype/event/proxy
                                if given an ID =&gt; edit, otherwise form for add
                auth            info about who is making the request(s)
                change          change a job/chunk/charset/jobtype/event/proxy
                confirm         ask for confirmation to delete an object
                del             delete object
                form            request a forms to fill in for editing/adding
                help            serve a help overview or help page
                info            same as auth, but from proxy for other clients
                report          report back a chunk (work or test case)
                request         type: 
                                  work - request more work
                                  test - request testcases (usually before work)
                                  file - request download URL for a file
                status          request a status page with statistics
                terminate       request termination of a client
                reset           reset a client's error counters and status tables</pre>



</div>

<h3><a name="output">Output</a></h3>

<div class="text">

<p>The output for <code>status</code>, <code>form</code>, <code>change</code>, <code>confirm</code>, <code>del</code>, <code>help</code>, <code>add</code>,
<code>reset</code>, <code>terminate</code> and <code>add</code> are always in human-readable HTML, while the
others are in plain text so that the client can parse them more easily.</p>

<p>The text answers look like:</p>

<pre>
        &lt;PRE&gt;
        req0001 201 Ok
        req0002 401 Your are not owner</pre>

<p>Any line that does not follow the format <strong>req[0-9]+\s[0-9]+</strong> (aka starts with
request number and response code) is to be ignored by the client. This allows
the server to send HTML or comments along with the text.</p>

<p>The first part is the request number the client did sent, followed by the
error/responce code and an additional clear text message (for logging/user
output or the response for work/test requests).</p>

<p>Another example of server output, this time from an actual request:</p>

<pre>
        &lt;PRE&gt;
        req0000 099 Helo 'test'
        req0000 099 Server localtime Tue Mar 27 17:39:23 2001
        req0000 099 debug 0.0292005406963689 0.9
        req0012 200 job_2;set_2;worker_test-2.00;chunk_3;token_1234;start_616161;end_62616161;target_656565;</pre>

<p>As seen above, <code>req0000</code> are general answers, while <code>req0012</code> identifies the
answer belonging to the <code>req0012</code> the client sent.</p>

<p>A list of ranges for the different codes (the number after the request, f.i.
<code>099</code>) can be found in <a href="#clienthandling_of_server_responses">CLIENT-HANDLING OF SERVER RESPONSES</a>, the complete
list of messages and their numbers is in <code>msg/messages.txt</code>.</p>



</div>

<h3><a name="complete_parameter_structure">Complete parameter structure</a></h3>

<div class="text">

<p>A complete list of all allowed requests and their parameters can be found
in the file <code>def/requests.def</code>. This file is read and parsed by the
server and represents the actual configuration.</p>

<p>Likewise, for the client the valid requests are stored in
<code>def/client_requests.def</code>. The client only knows a handfull of different
requests like getting work, testcases and download locations of files,
as well as submitting it's results to the server.</p>



</div>

<h3><a name="sending_info_to_the_server">Sending info to the server</a></h3>

<div class="text">

<p>The <code>auth</code> request or the <code>info</code> request (think about a 'request to note
this information about me':) is the way for the client to authentice itself
to the server and send info about itself and it's (hardware) status to the
server. <strong>Required</strong> parameters are:</p>

<pre>
        version         client version
        id              the client ID this info relates to
        arch            architecture, same string as used to start worker
                        examples: win32, linux, os2 etc</pre>

<p>For <code>info</code> requests, this field is also mandatory:</p>

<pre>
        for             The requests this info record belongs to. A Proxy
                        might send requests from more than one client, and
                        the for field let's the identify which requests belong
                        to which client.</pre>

<p>Additional, <strong>optional</strong> parameters are:</p>

<pre>
        temp            the client's cpu/case temperature (only one value)
        fan             speed of fan (only one value)
        os              operating system and version
        cached          from which jobs chunks are cached
        chatter         Server may ignore the text of this parameter
                        (or even chatter back! &gt;:+]
        cpuinfo         names and Mhz of cpu's
        ip              ip address of the client when coming via proxy</pre>

<p>Each list of requests (except for commands like <code>status</code>, <code>add</code> and
<code>change</code>) by the client (or proxy) to the server must contain
an <code>auth</code> request in it and this must contain at least the required
parameters. Otherwise all the requests from the client will be denied!</p>

<p>In case of a proxy, the proxy will authenticate itself with it's own <code>auth</code>
request, while all the clients <code>auth</code> requests are send as <code>info</code>.</p>

<p>Thus if client 5 (running version 0.24, ip 1.2.3.4) sends as <code>auth</code> to the
proxy:</p>

<pre>
        req0001=cmd_auth;id_5;version_0.24
        req0002=cmd_request;type_test</pre>

<p>The proxy (id 7, version 0.25) will send to the server (including the IP
of the client for verification):</p>

<pre>
        req0001=cmd_auth;id_7;version_0.25
        req0002=cmd_info;id_5;version_0.24;ip_1.2.3.4;for_req0003 
        req0003=cmd_request;type_test</pre>

<p>Note that the request numbers send from the proxy to the server have nothing
to do with the request numbers received from the client, they are generated
on the fly, and the answer from the server will be translated back to the client
space:</p>

<p>Answer from server to proxy:</p>

<pre>
        req0000 99 I like cheese.
        req0003 200 ... test case here</pre>

<p>The proxy will answer back to the client:</p>

<pre>
        req0002 200 ... test case here</pre>



</div>

<h3><a name="further_examples">Further Examples</a></h3>

<div class="text">
<pre>
        req0002=cmd_info;chatter_The+heaven+has+crashed+on+me</pre>

<p>No explanation necessary ;)</p>



</div>

<h3><a name="reporting_back_results">Reporting back results</a></h3>

<div class="text">

<p><code>cmd=report</code> has the following additional parameters:</p>

<pre>
        chunk                   the chunk ID for which the result is
        crc                     the crc of the chunk (from the worker)
        job                     which job the chunk belongs to (ID)
        status                  status of chunk-result
        took                    time in seconds it took to do the chunk
        token                   the secret token the server gave the client
        result                  optional result (if status = SOLVED)
        reason                  an optional error message (if status = FAILED)</pre>

<p>This is used both for test cases and real work.</p>

<p>The parameter <code>status</code> can have the following literal values:</p>

<pre>
        SOLVED                  found a result
        DONE                    found no result
        FAILED                  did not work at chunk (aborted or error)
        TIMEOUT                 did not complete work on chunk</pre>



</div>

<h3><a name="requesting_test_cases">Requesting test cases</a></h3>

<div class="text">

<p>Test cases are used by DiCoP to ensure that the client and workers
work correctly. Each defined testcase on the server has a known result
and the client is expected to return that result to the server.</p>

<p><code>cmd=request</code>, type <code>test</code> does not have any additional parameters.</p>

<p>Example:</p>

<pre>
        req0001=cmd_request;type_test</pre>



</div>

<h3><a name="requesting_more_work">Requesting more work</a></h3>

<div class="text">

<p><code>cmd=request</code>, type <code>work</code> has the following additional parameters:</p>

<pre>
        size                    the prefered chunk size (in minutes)
        count                   optional count of same-sized chunks the client
                                wants to have, default 1</pre>

<p>Example:</p>

<pre>
        req0001=cmd_request;type_work;size_100;count_1</pre>



</div>

<h3><a name="requesting_files__autoupdating_">Requesting files (auto-updating)</a></h3>

<div class="text">

<p>When the client detects that a worker or target file has a wrong hash, it
will automatically (see config on how to disable this) download the file.</p>

<p>This is done by asking first the main server where to get the file, and the
finally downloading the file. The downloaded file is then hashed to ensure
its integrity.</p>

<p><code>cmd=request</code>, type <code>file</code> takes only one additional parameter:
</p>

<pre>

        name                    the relative path of the wanted file</pre>

<p>The name <strong>must</strong> start with <code>worker/</code> or <code>target/</code>, anything else will
result in an error. In addition, the filename cannot contain '..' or similiar
constructs to avoid attacks on the server.</p>

<p>Example:</p>

<pre>
        req0001=cmd_request;type_file;name_worker/linux/test.pl</pre>

<p>The answer from the server will look like:</p>

<pre>
        req0001 101 1234567890abcdef <a href="http://server.invalid:80/test.pl">http://server.invalid:80/test.pl</a></pre>

<p>The first part is the hash (currently always MD5), and the second the URL
where to get that particular file.</p>

<p>The client ca send in more than one request for a file per connect:</p>

<pre>
        req0001=cmd_request;type_file;name_worker/linux/this
        req0002=cmd_request;type_file;name_worker/linux/that</pre>

<p>The server will answer them correctly.</p>



</div>

<h3><a name="requesting_status_pages">Requesting status pages</a></h3>

<div class="text">

<p>This produces human/browsers readable output for statistics and control.</p>

<p>Only one parameter, with additional sub-parameters depending on type:</p>

<pre>
        type                    the type of status page as detailed below</pre>

<p>The type can be (sub parameters are shown indended):</p>

<pre>
        server                  detailed status of the server/cluster
        main                    main status page (job listing)
                filter          filter out jobs that have a status listed here
                                SOLVED, DONE, TOBEDONE, SUSPENDED
        job                     display a job in detail
                id              the job ID to show
        results                 display all results
        cases                   display all cases
        case                    details for this case   
                id              the id of the case to display
        clients                 display stats on clients
                id              detailed stats for this client
                count           'count' sourrounding clients (need also id)
                top             'top' clients (top_10 =&gt; Top 10)
                sort            sort clients, is one of the following strings:
                                'keys', 'id', 'name' or 'speed'
        client                  details for one of the clients
                id              the id of the client
        chunks                  all open (issued to clients) chunks
        proxies                 list of all known proxies
        charsets                list of all known charsets
                id              highlight this charset
        charset                 details for one charset
        jobtypes                list of all known job types
                id              highlight this jobtype
        groups                  list of all known groups
                id              highlight this group
        testcases               list of all known test cases (test jobs)
        users                   list of all users (administrators)
        clientmap               a shorter overview over all clients
        search                  show the search form page
        del                     show a form to delete one object
                id              the id of the object to delete
                type            the type of the object to delete</pre>

<p>Examples:</p>

<p>All the current running (status = <code>TOBEDONE</code>) jobs:</p>

<pre>
        req0001=cmd_status;type_main;filter_SOLVED,DONE,SUSPENDED</pre>

<p>All the SOLVED jobs:
</p>

<pre>

        req0001=cmd_status;type_main;filter_TOBEDONE,DONE,SUSPENDED</pre>

<p>Job #5 and it's gory details:</p>

<pre>
        req0001=cmd_status;type_job;id_5</pre>

<p>Details for client #10:</p>

<pre>
        req0001=cmd_status;type_clients;id_10</pre>

<p>Ranking for client #10 and 20 clients 'around' it:
</p>

<pre>

        req0001=cmd_status;type_clients;id_20;count_20</pre>



</div>

<h3><a name="requesting_help_pages">Requesting Help Pages</a></h3>

<div class="text">

<p>To request a help page, you use the <code>help</code> command with a <a href="#item_type"><code>type</code></a> of one of the
following:</p>

<pre>
        list
        client
        config
        dicop
        dicopd
        objects
        files
        glossary
        proxy
        security
        server
        trouble
        worker</pre>

<p>Some examples:</p>

<p>Requesting the help overview page:</p>

<pre>
        req0001=cmd_help;type_list</pre>

<p>Requesting the help about the config file:
</p>

<pre>

        req0001=cmd_help;type_config</pre>



</div>

<h3><a name="requesting_forms">Requesting Forms</a></h3>

<div class="text">

<p>To request a form to add something or change something, you use the <code>form</code>
command.</p>

<p>The parameter <a href="#item_type"><code>type</code></a> specifies which form you request. If you supply a
parameter <code>id</code>, you get a form to change the job/chunk/charset etc, otherwise
you get a form for adding something.</p>

<p>Possible types, which should be self-explanatory:</p>

<pre>
        job
        chunk
        charset
        client
        jobtype
        group
        proxy
        testcase
        user</pre>

<p>Some examples:</p>

<p>Requesting the form to add another job:</p>

<pre>
        req0001=cmd_form;type_job</pre>

<p>Requesting the form to add another charset:</p>

<pre>
        req0001=cmd_form;type_charset</pre>

<p>You can not add a chunk, so this results in an error:
</p>

<pre>

        req0001=cmd_form;type_chunk</pre>



</div>

<h3><a name="adding_a_job">Adding a job</a></h3>

<div class="text">

<p>You use the <code>add</code> command with parameter <a href="#item_type"><code>type</code></a> set to 'job' for this.</p>

<p>For a list of the additional parameters see <code>def/requests.def</code>.</p>

<p>To get the form to fill in see <a href="#requesting_forms">REQUESTING FORMS</a>.</p>



</div>

<h3><a name="adding_other_objects">Adding other objects</a></h3>

<div class="text">

<p>For a list of the additional parameters see <code>def/requests.def</code>.</p>



</div>

<h3><a name="deleting_objects">Deleting Objects</a></h3>

<div class="text">

<p>You can find the object to delete by using the search form, or by viewing
the status pages of single objects (like a single client).</p>

<p>Then you use the <code>confirm</code> command with parameter <code>id</code>. <a href="#item_type"><code>type</code></a> must be
one of the valid object types.</p>

<p>This will give you a form to confirm the delete. To actually delete something,
use <code>del</code> with <a href="#item_type"><code>type</code></a> and <code>id</code>.</p>

<p>Objects are only deletable if they are not currently used by other objects.
For instance, a charset used by any job cannot be deleted - You would need to
delete the job first. The server will automatically check this and warn you
if deletion is not possible.</p>



</div>

<h3><a name="changig_a_job_chunk">Changig a job/chunk</a></h3>

<div class="text">

<p>You use the <code>change</code> command for this, typically by filling in a www-form.
You request this form with <code>form</code>, see <a href="#requesting_forms">REQUESTING FORMS</a>.</p>

<p>Requesting the form to change job #5:</p>

<pre>
        req0001=cmd_form;type_job;id_5</pre>

<p>Requesting the form to change chunk #3 of job #5:
</p>

<pre>

        req0001=cmd_form;type_chunk;id_3;job_5</pre>

<p>Submitting the forms is done via submit button and uses the command <code>change</code>.</p>



</div>

<h3><a name="a_chunk_of_work">A chunk of work</a></h3>

<div class="text">

<p>The server will send the following fields for each requested chunk of work. If
the client requested more than one chunk at the same time, there might be
multiple answers to his request, each of them containing the same fields with
different contents.</p>

<dl>
<dt><strong><a name="item_set">set</a></strong><br />
</dt>
<dd>
The character set (ID) to use. Will be passed on to the worker. If the charset
ID is not a number, then it will be interpreted as <em>chunk description file</em>
name and only this filename will be given to the worker. The server will
automatically tell the client that this file must be present (so it will be
downloaded if nec.).
</dd>



<dt><strong><a name="item_start">start</a></strong><br />
</dt>
<dd>
Start password/key of chunk.
</dd>



<dt><strong><a name="item_end">end</a></strong><br />
</dt>
<dd>
End password/key of the chunk.
</dd>



<dt><strong><a name="item_token">token</a></strong><br />
</dt>
<dd>
A secret token the server expects back when the client reports the result.
</dd>



<dt><strong><a name="item_worker">worker</a></strong><br />
</dt>
<dd>
The name of the worker. This is not the full executable name (like test.pl or
test.exe, merely just the basis name <code>test</code>). It is the responsibility of the
client to pick the right worker path (according to the architecture the client
runs on) and extension (for operating systems that mark executables with an
extension like <code>.exe</code>).
</dd>
<dd>

<p>Sub-architectures are to be ignored, so that a client running on <code>linux-i386</code>
needs to request to download <code>worker/linux/foo</code> and not
<code>worker/linux/i386/foo</code>. The server will automatically serve the right file
for you.</p>

</dd>



<dt><strong><a name="item_target">target</a></strong><br />
</dt>
<dd>
The target data to be passed to the worker. Either a hash in hex (or some
other hexified data) or the name of a target file.
</dd>
<dd>

<p>See also <a href="#target_file_vs__target_hash">TARGET FILE VS. TARGET HASH</a>.</p>

</dd>



<dt><strong><a name="item_targethash">targethash</a></strong><br />
</dt>
<dd>
This field is no longer used. A message 101 will be sent along with the
answers to tell the client the hash and name of the target file, in case
the target really is a file.
</dd>
<dd>

<p>See also <a href="#target_file_vs__target_hash">TARGET FILE VS. TARGET HASH</a>.</p>

</dd>

</dl>

<p>The following additional fields may also be present for information purposes:</p>

<dl>
<dt><strong><a name="item_job">job</a></strong><br />
</dt>
<dd>
The ID of the job this chunk belongs to.
</dd>



<dt><strong><a name="item_size">size</a></strong><br />
</dt>
<dd>
Number of passwords in this chunk.
</dd>



<dt><strong><a name="item_type">type</a></strong><br />
</dt>
<dd>
The jobtype.
</dd>



<dt><strong><a name="item_chunk">chunk</a></strong><br />
</dt>
<dd>
The ID of the chunk.
</dd>

</dl>

<p>In addition, one or more messages with the number 101 will be send. These
contain names of additional files that must be present for each jobs the
client works on; the files must therefore be present and checked to have the
correct hash.</p>

<p>Each of the code 101 messages contains a request ID. If this ID is <strong>req0000</strong>,
then the file must be present for all chunks. If it is some other request ID
like <strong>req0002</strong>, then the file in question must only be present for answer to
the specific request. This allows the client to ignore work for requests it
cannot get all files, and work on the others instead.</p>

<p>Here is a complete example for an answer from the server:</p>

<pre>
        req0000 101 abcdef0123456789 &quot;charsets.def&quot;
        req0001 101 0123456789abcdef &quot;10.set&quot;
        req0001 200 job_10;chunk_3;token_1234;set_15;worker_test;start_6565;end_656565;hash_1234;target_646561</pre>

<p>If the <code>test</code> worker does have a different hash than 123456789, it should
be downloaded and hashed to ensure that the right worker is present. To get
the download location, the client must request it from the server via the
<code>request file</code> command, see
<a href="#requesting_files__autoupdating_">REQUESTING FILES (AUTO-UPDATING)</a>.</p>

<p>The same for the files <code>charsets.def</code> and <code>10.set</code>.</p>



</div>

<h3><a name="a_testcase">A testcase</a></h3>

<div class="text">

<p>The server response to requesting a testcase is more or less exactly the
same than when requesting work.</p>

<p>Usually the sever will respond to one request for tests with multiple answers.</p>

<p>See <a href="#a_chunk_of_work">A CHUNK OF WORK</a> for details.</p>



</div>

<h3><a name="clienthandling_of_server_responses">Client-handling of server responses</a></h3>

<div class="text">

<p>The client has to handle all the server replies and depending on the server's
response code, throw away or retry the request or start to work on it.</p>

<p>Request answers relating to <code>req0000</code> are not related to any specifiy
request, but of general nature. Otherwise the request number relates to the
request made by he client. The server may send more than one answer per
request, f.i. when requesting testcases or more than one chunk of work, you
might get back quite a list of responses, all relating to the same request.</p>

<p>Here is a list of status numbers and the action to be taken:</p>

<pre>
        status number   description             action
        --------------------------------------------------------------
        000..099        ok                      ignore
        100..199        ok                      system/status message
        200..299        ok                      work on it, or ignore
        300..399        not ok                  retry this request later
        400..449        single request not ok   don't retry this request
        450..499        all request(s) not ok   don't retry this request-list 
        500..           internal server error   retry all requests later on</pre>

<p>In case of error code 450 and up, the client should consider
the entire connect to the server failed.</p>

<p>If the error code is between 450 and 500, the client does not need to bother
to retry the session, it would fail again. On code 500 and up, the requests
should be send to the server again after waiting a certain time, at least 5
minutes.</p>

<p>Quite important are messages with the code 101 and 102 - these are files
that the client needs to download.</p>

<p>Message 101 is a normal file, while message 102 constitutes a temporary file
which should be deleted after the work on the chunk is done.</p>



</div>

<h3><a name="example">Example</a></h3>

<div class="text">

<p>This is a longer example of two clients with different speed requesting
work trough a proxy:</p>

<p>This request is send from client 1 (id 1, 20 minutes chunk size) to the proxy:</p>

<pre>
        req0001=cmd_request;type_work;size_20;count_1
        req0005=cmd_auth;id_1;version_0.24;arch_win32</pre>

<p>The proxy (id 5) thus asks the server:</p>

<pre>
        req0001=cmd_auth;id_5;version_0.25;arch_linux 
        req0002=cmd_request;type_work;size_20;count_1
        req0003=cmd_info;version_0.24;arch_win32;for_req0002</pre>

<p>The server responds like this to the proxy:</p>

<pre>
        req0002 203 job_10;chunk_3;token_1234567890j;set_15</pre>

<p>(start and end fields have been omitted for clarity, the tokens are made up
and will be different in reality)</p>

<p>and the proxy hands this to the client:</p>

<pre>
        req0001 203 job_10;chunk_3;token_1234567890j;set_15</pre>

<p>Now client 2 (id 2, 10 minutes) comes and asks the proxy for work:</p>

<pre>
        req0001=cmd_request;type_work;size_10;count_1
        req0005=cmd_auth;id_2;version_0.26;arch_linux</pre>

<p>The proxy (id 5) thus asks the server for work:
</p>

<pre>

        req0001=cmd_request;type_work;size_10;count_1
        req0002=cmd_auth;id_5;version_0.25;arch_linux 
        req0003=cmd_info;id_2;version_0.26;arch_linux;for_req0002</pre>

<p>The server responds like this to the proxy:</p>

<pre>
        req0001 203 job_11;chunk_5;token_1234567890k;set_15;worker_des</pre>

<p>(start and end fields have been omitted for clarity, the tokens are made up
and will be different in reality)</p>

<p>Proxy then hands out one to client 2:</p>

<pre>
        req0001 203 job_11;chunk_5;token_1234567890k;set_15</pre>

<p>Then some time later client 1 reports back a result:</p>

<pre>
        req0001=cmd_report;job_10;chunk_3;status_done;token_1234567890j
        req0002=cmd_auth;id_1;version_0.24;arch_win32</pre>

<p>The proxy hands this back to the server.</p>

<p>Note: The proxy could remember what it gave to the client and only accepts
this back. This is currently not implemented. XXX TODO</p>



</div>

<h2><a name="target_file_vs__target_hash">TARGET FILE VS. TARGET HASH</a></h2>

<div class="text">

<p>XXX TODO</p>



</div>

<h2><a name="ensuring_data_integrity">ENSURING DATA INTEGRITY</a></h2>

<div class="text">

<p>The <code>server</code> will write it's modified data back after each request. <code>dicopd</code>
will only write the data back after some specified time intervall.</p>

<p>If <code>dicopd</code> crashes, you might loose some <code>hour(s)</code> of computing time, but this
happens so infrequently that writing back the data in shorter intervalls is not
worth it.</p>

<p>By making a nightly backup of the entire <code>data/</code> directory, preferable to
another machine, you can ensure that in critical events (like a hard disk
crash) you can restore your server to the state it was the night before.</p>

<p>In the event that the backup happened while the server was writing data back,
you could restore the backup from the night before. Since the backup time is
likely to be small, and the data flush happens infrequently, this backup should
be good.</p>

<p>Some clients might then generate error messages, but these can (and will) be
ignored and everything will be back to normal in a very short time. Most of the
errors will come from clients that got chunks after the backup happened, and
then are not able to report them back (because the chunks do not yet exist, or
have the wrong token). The unique token for each chunk ensures that only the
right client can report his work back.</p>



</div>

<h2><a name="perfromance">PERFROMANCE</a></h2>

<div class="text">



</div>

<h3><a name="old_model__dicop_v1_x_and_server_v2_x_">Old model (dicop v1.x and server v2.x)</a></h3>

<div class="text">

<p>The (very) old implementation (v1.x) using Apache and running the client/server
on the same computer (300 MHz PIII under Linux) takes nearly 1.3 seconds for
each request. Ouch. This is because for every request the Perl script must be
loaded from disk (or cache), compiled and executed, and then the script laods
every data file.</p>

<p>The new client/server combination (v2.x, using &lt;server&gt; and Apache) was even
slower, since it is spread over more Perl files, consists of more Perl code,
and reads in more files. Also, the new method of calculating with passwords
(Math::String, Math::BigInt) takes much more time. This is the price for the
features and the better code we had to pay.</p>

<p>Note: The new server model (v2.x style) only required one connect from the
client for multiple requests, typically halving the number of connects. This
did combat the effect somewhat by halving the time spend with each client.</p>



</div>

<h3><a name="new_model__dicopd_v2_x_">New model (dicopd v2.x)</a></h3>

<div class="text">

<p>To combat this situation, a dedicated deamon, called <code>dicopd</code>, was developed.</p>

<p>This deamon is started only once, and then holds all the data in memory all
the time. The data is written back to disk only now and then. The only timeto
handle a request is to parse the request, fetch the data for the client, and
build the answer. This is much faster than the <code>cgi-bin</code> script approach.
It also eliminates the need for Apache, which you would need even if you made
the server a mod-perl script. Thus memory consumption is also expected to be
lower.</p>

<p>There is still a place for an Apache server, namely as file server. But with
<code>dicopd</code>, the file server can be running on a different machine than the DiCoP
server.</p>

<p>The reason for a seperate file server is that <code>dicopd</code> is (for easier coding)
a single-threaded application, handling one request per time, e.g. never two
requests simultanously.</p>

<p>If <code>dicopd</code> was used by the clients to download files, no more than one
client could download a file at a time, all the while blocking <code>dicopd</code> for
all other clients. With using a second, extra server for
serving the files, multiple downloads (limited by network bandwidth) are
possible. Apache is suited to the task of serving big, static files and we
don't want to re-invent the wheel.</p>



</div>

<h3><a name="speed_of_server_vs__dicopd">Speed of server vs. dicopd</a></h3>

<div class="text">

<p>On a 300 Mhz PII a trip trough a server with very little data (11 jobs,
9 clients, 4 testcases, 9 charsets, 5 jobtypes, 8 results) takes:</p>

<pre>
        server  dicopd  action
        ------------------------------------
         3.1s    0.2s   get main status page
         4.2s    0.2s   get chunk (writes data back)</pre>

<p>As the amount of data increases (maybe you have 100, not nec. all running,
jobs, with a lot of testcases, clients and open chunks) the <code>server</code> will
take quite a <strong>LOT</strong> of time since it must re-read and re-write all data each
time.</p>

<p><code>dicopd</code> will remain largely uneffected, since the amount of data does not
influence the turn-around time that much - great efforts have been made to
optimize these cases and make <code>dicopd</code> respond in basically <code>O(1)</code> time to
nearly all requests.</p>



</div>

<h3><a name="maximum_possible_clients__2001_">Maximum possible clients (2001)</a></h3>

<div class="text">

<p>In our tests with 32 clients (with an average chunk time of about 40 minutes)
the daemon process used slightly less than 2.5% of the CPU time of the main
server machine (a 200 Mhz AMD K6 with 64Mb RAM).</p>

<p>In one test, we did run the server for roughly 5 days and 21 hours. The
<code>dicopd</code> process used (according to <code>ps ax</code>) 169 min and 15 sec CPU time
while handling 19257 requests on 6481 client connects (version v2.18).</p>

<p>The average number requests per connect is 3 because each client reports a
result, requests work and sends in his authentication request with each
connect. The number is slightly less than 3.0 since normal administrator/user
connects with a browser (for status pages etc) send in only one request per
connect, but happen seldom enough to not skew the numbers too much.</p>

<p>If you divide the 10155 seconds CPU time by the 6481 connects, you get an
average of 1.57 seconds CPU time per connect.</p>

<p>Based on the 2.5% CPU time usage and if you allow a maximum load of 30%
(to have some reserves for spikes and background jobs), you would be able to
handle roughly 300 to 350 clients with such a machine, without it breaking
into a sweat.</p>

<p>Of course, increasing the chunk time or caching at the client (to make fewer
requests) will increase the maximum possible number of clients. The same effect
is achived by proxies. You can also buy faster hardware as a last resort, f.i.
a 1.4 Ghz Athlon would probably be able to handle at least 8 times as much
clients as the 200 Mhz AMD (e.g. 2400 .. 2800 clients).</p>



</div>

<h3><a name="performance_status_update__2002_">Performance status update (2002)</a></h3>

<div class="text">

<p>Up to version v2.20, various optimizations have taken place (especially since
v2.18) and the performance is now much better. A 200 Mhz AMD K6 would be able
to handle at least 3000 clients (an improvement of a a factor of 10) without
any problems, and benchmarks indicate that a 800 Mhz PIII will be able to handle
about 20,000 clients with a CPU load of about 30% (allowing for spikes and
other background activity).</p>

<p>Using Math::BigInt::GMP v1.11 now makes the client status page about 8%
faster (older versions were slightly slower than using Calc). Other operations
are not much faster or slower when using GMP, so we now try to use it if
possible.</p>



</div>

<h3><a name="performance_status_update__summer_2003_">Performance status update (Summer 2003)</a></h3>

<div class="text">

<p>In v2.22, the time to flush the data back to the disk was reduced quite a lot.
The reason was that there was a bug, causing the server to write back a lot
of unnecessary data to the disk.</p>

<p>With 100 suspended testjobs, flushing the database back to disk every 2 hours
took formerly around 11% of the CPU time of the <code>dicopd</code> process, now it
takes about 2.5%. Meaning the deamon takes roughly 8% less CPU time. These
values depends largely on the number of non-runnning jobs you have, e.g. the
more you have, the more time the new version will save you.</p>



</div>

<h3><a name="performance_status_update__fall_2003_">Performance status update (Fall 2003)</a></h3>

<div class="text">

<p>In a long-term test we did run the server for 27 days, and 19 hours on the
aforementioned AMD K6 200 Mhz with 128 MByte memory (Yes, it is an old
machine - probably the oldest still running. The uptime is 451 days, if you
must ask :)
</p>

<pre>

There were no crashes, or memory leaks. After that time the C&lt;dicopd&gt; process
used 22496 KBytes of memory (as shown with C&lt;top&gt;) and 196 minutes and 38
seconds of CPU time (according to C&lt;ps ax&gt;). All the flushes took 346
seconds.</pre>

<p>There were 38426 client connects (and 115304 requests) after that time.</p>

<p>This means that <code>dicopd</code> used 11798 - 346 seconds = 11452 seconds handling
client requests (CPU time spend minus flush time spend).</p>

<p>Divided by the number of connects, the average time is 0.298 seconds, or 
about 0.3 seconds per client connect.</p>

<p>With one client connect per second the server load would be at roughly 30%,
and using this as the maximum we can handle we arrive at the number of
3600 client connects per hour. If each clients connects once per hour (a
good practical value), the server would be able to handle roughly 3600
clients. This is about 20% more than the previous version.</p>

<p>We did not do long-term tests with more modern hardware yet, but one can
expect a substantial increase in the amount of clients such a machine could
handle.</p>

<p>Especially since the readily available hardware has developed further since
the last status updates, and AMD CPUs with 2 (real) Ghz or the equivalent
Intel CPU are now becoming quite cheap.</p>



</div>

<h3><a name="network_performance__2001_">Network performance (2001)</a></h3>

<div class="text">

<p>The network performance was not yet measured, and we do not know how much
traffic 1000 clients would exactly generate. Some simple statistics show that
each client connect takes only a couple hundred bytes.</p>

<p>When each client connects every 30 minutes to the server, it should not
generate more than 3 Kbytes traffic on average (YMMV).</p>

<p>Since our test server (200 Mhz K6 AMD, 64 MByte RAM) could handle 300 clients,
that would amuount to 600 connects per hour, with 600*3 KBytes traffic per
hour, or 0.5 KByte per second.</p>

<p>Having a faster network might help. A Proxy certainly will help, since it
increases the amount of data traveling slightly, but makes fewer connections.</p>

<p>Compressing the data might also help, but would need more CPU power at the
server/proxy, not to mention that it is not implemented yet. Compressing the
data might well not worth the effect.</p>



</div>

<h3><a name="network_performance__update_2003_">Network performance (update 2003)</a></h3>

<div class="text">

<p>Since our test server (200 Mhz K6 AMD, 128 MByte RAM) could handle easily 3600
clients, that would amuount to 3600 connects per hour, with roughly 3600*3
KBytes traffic per hour, or roughly 3 KBytes per second. Note that exact
measurements were not done.</p>

<p>A faster server with more clients would of course generate more network
traffic.

</p>



</div>

<h2><a name="todo">TODO</a></h2>

<div class="text">

<p>Please see also the TODO and BUGS files.

</p>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004

</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.

</p>



</div>


