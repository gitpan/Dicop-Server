<!-- template for case list with one template entry between start/end -->


<div class="menu">
<a class="h" href="##selfhelp_list##" title="Get help">Help</a> |
<a class="h" href="##selfform_case##" title="Add a new case">Add</a>
</div>

<h1><a class="h" href="##selfstatus_main##">DiCoP</a> - All Cases</h1>

<div class="text">

<table>

<tr class="head">
 <th><a class="h" href="##selfstatus_cases##;sort_up;sortby_id" title="Sort by ID">ID</a></th>
 <th><a class="h" href="##selfstatus_cases##;sort_downstr;sortby_name" title="Sort by number">Number</a></th>
 <th><a class="h" href="##selfstatus_cases##;sort_upstr;sortby_description" title="Sort by description">Description</a></th>
 <th><a class="h" href="##selfstatus_cases##;sort_upstr;sortby_referee" title="Sort by referee">Referee</a></th>
 <th>Link</th>
 <th><a class="h" href="##selfstatus_cases##;sort_up;sortby_jobs" title="Sort by nr. of jobs">Jobs</a></th>
</tr>

<!-- start -->
<tr>
 <td><a href="##selfform_case##;id_##id##" title="Click to change settings">##id##</a></td>
 <td><a href="##selfstatus_case##;id_##id##" title="View case details">##name##</a></td>
 <td>##description##</td>
 <td>##referee##</td>
 <td><a href="##url##" title="##url##">More...</a></td>
 <td>##jobs##</a></td>
</tr>
<!-- end -->

</table>

</div>
