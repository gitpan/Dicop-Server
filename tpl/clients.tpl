<!-- template for client list with one template entry between start/end -->

##include_menu_clientmap.inc##

<h1><a class="h" href="##selfstatus_main##">DiCoP</a> - Client list</h1>

<div class="text">

<p>
I know <b>##clientcount##</b> clients, <b>##online##</b> of them are currently online, while 
<b>##offline##</b> of them seem to be offline or did not connect yet.
</p>

<table>

<tr class="head">
 <th rowspan=2>Rank</th>
 <th rowspan=2><a class="h" href="##selfstatus_clients##;sort_name" title="Sort list by name">Name</a></th>
 <th rowspan=2><a class="h" href="##selfstatus_clients##;sort_id" title="Sort list by ID">ID</a></th>
 <th rowspan=2><a class="h" href="##selfstatus_clients##;sort_speed" title="Sort list by speed">Speed</a></th>
 <th colspan=3>Passwords</th>
 <th colspan=4>Chunks</th>
 <th colspan=2>Running</th>
 <th colspan=2>Last</th>
</tr>
<tr class="head">
 <th><a class="h" href="##selfstatus_clients##;sort_keys" title="Sort list by keys done">Keys</a></th>
 <th>Diff</th>
 <th>Percent</th>
 <th>Done</th>
 <th>Lost</th>
 <th>Millions</th>
 <th>Percent</th>
 <th>for</th>
 <th>version</th>
 <th><a class="h" href="##selfstatus_clients##;sort_online" title="Sort list by online status">connect</a></th>
 <tH>chunk</th>
</tr>

<!-- start -->
<tr>
 <td align=right>##rank##</td>
 <td><a href="##selfstatus_client##;id_##id##">##name##</a></td>
 <td>##id##</td>
 <td>##speed##</td>
 <td align=right>##done_keys##</td>
 <td>&nbsp;##done_diff##</td>
 <td align=right>##done_percent##</td>
 <td align=right>##done_chunks##</td>
 <td align=right>&nbsp;##lost_chunks##</td>
 <td align=right>##lost_keys##</td>
 <td align=right>##lost_percent##</td>
 <td align=right>##uptime##</td>
 <td align=left>##version##</FONT></TD>
 <td class="##last_connectcolor##">&nbsp;##last_connect##</td>
 <td class="##last_chunkcolor##">&nbsp;##last_chunk##</td>
</tr>
<!-- end -->

</table>

<p>
Click onto the name of a client to see details for it.
You can go to <a href="##selfstatus_main##">main</a>
or <a href="##selfform_client##">add</a> another client.
</p>
</div>
