
##include_menu_main.inc##

<h1>DiCoP - Main Status</h1>

<div class="text">

<p>
 I know <b>##clients## <a href="##selfstatus_clients##" title="View client list">clients</a></b>
 (<b><A HREF="##selfstatus_clientmap##" title="View clientmap">clientmap</a></b>)
 (<b>##proxies##</b> of them are <b><a href="##selfstatus_proxies##" title="View proxies">proxies</a></b>),
  belonging to <b>##groups##</b> different
 <b><A HREF="##selfstatus_groups##" title="View groups">groups</a></b>. I know
 <b>##jobtypes## <a href="##selfstatus_jobtypes##" title="View job types">job types</a></b>,
 <b>##testcases## <a href="##selfstatus_testcases##" title="View testcases">test cases</a></b>, and 
 <b>##charsets## <a href="##selfstatus_charsets##" title="View charsets">char sets</a></b>. 
</p>

<p>
 My job list contains <b>##jobs##</b> jobs in
 <b>##cases## <a href="##selfstatus_cases##" title="View cases">cases</a></b>,
 <b>##tobedone##</b> of them are
 still running, <b>##failed##</b> failed (were finished without result) and
 <b>##suspended##</b> are suspended.
 I found <b>##results## <a href="##selfstatus_results##" title="View result list">results</a></b>
 for all the jobs until now.
 There is a list of all <B><A HREF="##selfstatus_chunks##" title="View open chunk list">open chunks</A></B>.
 See also my <B><A HREF="##selfstatus_server##" title="Show detailed status page">detailed status</A></B> page.
</p>

</div>

<h2 style="float: left;">Joblist</h2>

##include_menu_joblist.inc##

<div class="text">

##joblist##

<p class="small">
 The number in () after the priority gives the rough percent value of CPU
 time of the cluster that will be used for that job. The job(s) with the lowest
 rank will get a fixed amount of percent (e.g. 90%), which is shared equally
 be them (e.g. 3 jobs with the same minimum rank will get each 33.33%). The
 others jobs will get the rest of priority distributed equally, e.g. 4 other
 jobs would get 2.5% each.
</p>

</div>

