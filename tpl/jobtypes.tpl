<!-- template for job type list with one template entry between start/end -->

##include_menu_jobtypes.inc##

<h1><a class="h" href="##selfstatus_main##" title="Back to main page">DiCoP</a> - All Job Types</h1>

<div class="text">

<table>

<tr>
 <th><a class="h" href="##selfstatus_jobtypes##;sort_up;sortby_id" title="Sort by ID">ID</a></th>
 <th><a class="h" href="##selfstatus_jobtypes##;sort_upstr;sortby_name" title="Sort by name">Name</a></th>
 <th><a class="h" href="##selfstatus_jobtypes##;sort_upstr;sortby_description" title="Sort by description">Description</a></th>
 <th><abbr title="Default speed in keys/s">Speed</abbr></th>
 <th><abbr title="Number of fixed characters for each key">Fixed</abbr></th>
 <th><abbr title="Prefered charset for jobs of this type">Charset</abbr></th>
 <th><abbr title="Minimum password lenght">Minlen</abbr></th>
</tr>

<!-- start -->
<tr>
 <td><a href="##selfform_jobtype##;id_##id##" title="Click to change jobtype settings">##id##</a></td>
 <td>##name## (v##version##)</td>
 <td>##description##</td>
 <td>##speed##</td>
 <td>##fixed##</td>
 <td><a href="##selfstatus_charset##;id_##charset##" title="##charset_description## (Click to view charset)">##charset##</a></td>
 <td>##minlen##</td>
</tr>
<!-- end -->

</table>

<p>
The speed is in keys/second, approximately.
</p>

<p>
Click onto the ID of any of the jobtypes to change it's settings.
</p>

</div>
