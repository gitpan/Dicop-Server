<!-- template for client map with one template entry between start/end -->

##include_menu_clientmap.inc##

<h1><a class="h" href="##selfstatus_main##" title="Back to main page">DiCoP</a> - Client map</h1>

<div class="text" style="padding-bottom: 1em;">

<p>
I know ##clientcount## clients, ##online## of them are currently online, while 
##offline## of them seem to be offline or did not connect yet.
</p>

<table>

<!-- start -->
<td class="##last_connectcolor##"><a href="##selfstatus_client##;id_##id##" title="##name##">##id##</a></td>
<!-- end -->

</table>

<p>
View <a href="##selfstatus_clientmap##;width_10">10</a>,
<a href="##selfstatus_clientmap##;width_16">16</a>,
<a href="##selfstatus_clientmap##;width_20">20</a>,
<a href="##selfstatus_clientmap##;width_25">25</a>,
<a href="##selfstatus_clientmap##;width_42">42</a>,
<a href="##selfstatus_clientmap##;width_50">50</a>,
<a href="##selfstatus_clientmap##;width_100">100</a> in a row...you get the
idea. Click onto the ID of a client to see details for it.
</p>

<span style="float: left">
Color code:
</span>

<table><tr>
<td class="online">online</td>
<td class="unknown">unknown</td>
<td class="nocon">never connected</td>
<td class="offline">offline</t
<td class="noreturn">did not yet return work</td>
</tr></table>

</div>

<div class="clear"></div>

<h3>Reset all clients</h3>

<div class="text">

<p>
The form below will reset all the clients, e.g. their speed, and remove all
their cached jobspeed values as well as their connect tracking, which will
re-enable the clients to connect if one of them was blocked by the
request-rate limit. Note that you can also reset single clients by using the
reset form at each of the client's individual status page.
</p>

##include_authform_float.inc##

<input type=hidden name="type" value="clients">
<input type=hidden name="cmd" value="reset">

<input type=submit class="submit" name="submit" value="Reset all clients" title="Reset all clients">
</form>

</div>

<h3>Terminate all clients</h3>

<div class="text">

<p>
The form below will send a terminate signal to all clients upon their next
connect (e.g. not immidiately, since the clients are not permanently
connected to the server).
<br>
If a client was started from a script running in an endless-loop
it will be redownloaded and restarted, e.g. getting updated.
<br>
If some clients were started manually, they will terminate and need
to be restarted manually again.
</p>

##include_authform_float.inc##

<input type=hidden name="type" value="clients">
<input type=hidden name="cmd" value="terminate">

<input type=submit class="submit" name="submit" title="Send terminate signal to all clients" value="Terminate all clients">
</form>

</div>

