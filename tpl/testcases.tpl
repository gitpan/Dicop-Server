<!-- template for test case list with one template entry between start/end -->

##include_menu_testcases.inc##

<h1><a class="h" href="##selfstatus_main##" title="Back to main">DiCoP</a> - All Test Cases</h1>

<div class="text">

<table>

<tr class="head">
 <th>ID</th>
 <th>Description</th>
 <th>Start</th>
 <th>End</th>
 <th>Jobtype</th>
 <th>Charset</th>
 <th>Result</th>
 <th>Extra params</th>
 <th>Disabled</th>
</tr>

<!-- start -->
<tr>
 <td><a href="##selfform_testcase##;id_##id##" title="Click to change settings">##id##</a></td>
 <td>##description##&nbsp;</td>
 <td class="code" title="##startlen## characters">##start##</td>
 <td class="code" title="##endlen## characters">##end##</td>
 <td><a href="##selfstatus_jobtypes##;id_##jobtype##" title="##jobtype_description##">##jobtype##</a></td>
 <td><a href="##selfstatus_charsets##;id_##charset##" title="##charset_description##">##charset##</a></td>
 <td class="code">##result##</td>
 <td>##extras##</td>
 <td>##disabled##</td>
</tr>
<!-- end -->

</table>

<p>
Click onto the ID to change a test case.
You can go to <a href="##selfstatus_main##">main</a>
or add another <a href="##selfform_testcase##">test case</a>.
</p>

</div>
