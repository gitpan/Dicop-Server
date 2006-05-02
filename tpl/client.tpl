<!-- template for details on a certain client -->

##include_menu_client.inc##

<h1><a class="h" href="##selfstatus_main##" title="Back to main">DiCoP</a> - Status of client ###id## - ##name##</h1>

<div class="text">

<p>
Client <b>##name##</b> (<b>##description##</b>) is running version
<b>##version##</b> on a <b>##cpuinfo##</b> under
<b>##os##</b> (<b>##arch##</b>).
</p>

<p> 
The client's average speed is factor (for all running jobs) is
<b>##speed_factor##</b>. The time between two chunks is <b>##chunk_time##</b>
(average over the last 16 chunks). 
</p>

<p>
The client's last connect was <b>##last_connect##</b>, and it returned the last
chunk <b>##last_chunk##</b>.
</p>

</div>

<h3>Speed and chunk counters</h3>

<div class="text">

##job_speed##

</div>

<H3>Failure counters and last error message</H3>

<div class="text">

##failures##

<p>
The last error message was sent on ##last_error## and reads:
</p>

<pre class="error">
##last_error_msg##
</pre>

<p>
To reset this client's status page, see the menu. If you want to reset the status of all clients,
go to the <a href="##selfstatus_clientmap##">clientmap page</a>.
</p>

</div>

