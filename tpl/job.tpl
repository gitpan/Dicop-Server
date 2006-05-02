<!-- template for job list with one template entry between start/end -->

<table>

<tr class="thead">
  <th>Case</th>
  <th>Job</th>
  <th>Description</th>
  <th>Done</th>
  <th>Start</th>
  <th>End</th>
  <th>Set</th>
  <th>Chunks</th>
  <th>Jobtype</th>
  <th>Status</th>
  <th>R</th>
  <th>Rank</th>
</tr>

<!-- start -->
<tr>
 <td class="id"><a href="##selfstatus_case##;id_##jobcase##" title="View case ##jobcase_name##">##jobcase_name##</a></td>
 <td class="id"><a href="##selfstatus_job##;id_##jobid##" title="View job">##jobid##</a></td>
 <td>##jobdescription##</td>
 <td title="##jobpercent_done##%, to go: ##jobwilltakesimple##"><div class="percent"><span class="percent" style="width: ##jobpercent_done_int##px"></span></div></td>
 <td class="code" title="##jobstartlen## characters">##jobstart##</td>
 <td class="code" title="##jobendlen## characters">##jobend##</td>
 <td><a href="##selfstatus_charsets##;id_##jobcharset##" title="##jobcharset_description##">##jobcharset##</a></td>
 <td align="right">##jobchunks##</td>
 <td><a href="##selfstatus_jobtypes##;id_##jobjobtype##">##jobjobtype_description##</a></td>
 <td class="##jobstatus##" title="Will be done at ##jobfinished##">##jobstatus##</td>
 <td><a href="##selfstatus_jobresults;id_##jobid####" title="Click to view results">##jobresults##</a></td>
 <td>##jobrank## (##jobpriority##%)</td>
</tr>
<!-- end -->

</table>
