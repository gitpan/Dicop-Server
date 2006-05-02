<!-- template for result list with one template entry between start/end -->

<table>

<tr class="head">
 <th><a class="h" href="##selfreq##;sort_down;sortby_job" title="Sort by job">Job</a></th>
 <th><a class="h" href="##selfreq##;sort_down;sortby_time" title="Sort by found date">Found on</a></th>
 <th><a class="h" href="##selfreq##;sort_up;sortby_type" title="Sort by jobtype">Jobtype</a></th>
 <th>Jobdescription</th>
 <th>Hex</th>
 <th>ASCII</th>
 <th><a class="h" href="##selfreq##;sort_up;sortby_client" title="Sort by client">Client</a></th>
</tr>

<!-- start -->
<tr>
 <td class="id"><a href="##selfstatus_job##;id_##job##" title="View job">##job##</a></td>
 <td>##time##</td>
 <td><a href="##selfstatus_jobtypes##;id_##type##">##type##</a> (##type_description##)</td>
 <td>##job_description##</td>
 <td class="code">##result_hex##</td>
 <td class="code">##result_ascii##</td>
 <td>&nbsp;<a href="##selfstatus_client##;id_##client##" title="View client id ##client##">##client_name##</a></td>
</tr>
<!-- end -->

</table>

