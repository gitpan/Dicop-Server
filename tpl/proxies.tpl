<!-- template for client list with one template entry between start/end -->

##include_menu_proxies.inc##

<h1><a class="h" href="##selfstatus_main##" title="Back to main page">DiCoP</a> - Proxy list</h1>

<div class="text">

<p>
The number of keys etc. refers to the work done by clients behind the proxy,
not the proxy machine itself.
<p>

<table>

<tr class="head">
 <th rowspan=2>Rank</th>
 <th rowspan=2>Name</th>
 <th rowspan=2>ID</th>
 <th colspan=3>Passwords</th>
 <th colspan=4>Chunks</th>
 <th colspan=2>Running</th>
 <th colspan=2>Last</th>
</tr>
<tr class="head">
 <th>Keys</th>
 <th>Diff</th>
 <th>Percent</th>
 <th>Done</th>
 <th>Lost</th>
 <th>Millions<th>Percent</th>
 <th>for</th>
 <th>version</th>
 <th>connect</th>
 <th>chunk</th>
</tr>

<!-- start -->
<tr>
 <td align=RIGHT>##rank##</td>
 <td><a href="##selfform_proxy##;id_##id##">##name##</a></td>
 <td>##id##</td>
 <td align=RIGHT>##done_keys##</td>
 <td>&nbsp;##done_diff##</td>
 <td align=RIGHT>##done_percent##</td>
 <td align=RIGHT>##done_chunks##</td>
 <td align=RIGHT>&nbsp;##lost_chunks##</td>
 <td align=RIGHT>##lost_keys##</td>
 <td align=RIGHT>##lost_percent##</td>
 <td align=RIGHT>##uptime##</td>
 <td align=LEFT>##version##</td>
 <td class="##last_connectcolor##">&nbsp;##last_connect##</td>
 <td class="##last_chunkcolor##">&nbsp;##last_chunk##</td>
</tr>
<!-- end -->

</table>

<p>
Click onto the name to change a proxy's settings.
You can go to <a href="##selfstatus_main##">main</a>
or add another <a href="##selfform_proxy##">proxy</a>.
</p>

</div>
