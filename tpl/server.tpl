
##include_menu_main.inc##

<h1><a class="h" href="##selfstatus_main##" title="Back to main">DiCoP</a> - Detailed Status</h1>

<div class="text">

<p>
 My name is <b>'##name##'</b> (type <b>##servertype##</b>) and I run DiCoP
 <b>v##version## (build ##build##)</b> under <b>##os##</b> as user
 <b>##user##</b>, group <b>##group##</b> (<b>##chroot##</b>) for now
 <b>##runningtime##</b>.
</p>

<p>
 I handled <b>##requests##</b> messages
  (<font size="-1"><b>##auth_requests##</b> auth, 
  <b>##status_requests##</b> status, 
  <b>##report_requests##</b> reports
  (<b>##report_work_requests##</b> work, <b>##report_test_requests##</b> test),
  <b>##request_requests##</b> requests
  (<b>##request_work_requests##</b> work, <b>##request_test_requests##</b> test)
  </font>)
 on <b>##connects##</b> client connects.
</p>

<p>
 It took <b>##all_connects_time##s</b> to handle all connects, <b>##last_connect_time##s</b>
 for the last connect, and the average time per connect
 is so far <b>##average_connect_time##s</b>.
</p>

<p>
 There is currently the equivalent of <b>##rawpower##</b> machines working in
 the cluster.
</p>

<p>
 Last data flush to disk was on <b>##last_flush##</b> (##last_flush_ago## ago).
 All the data flushes together took <B>##flush_time## seconds</b>. 
</p>

<p>
 I know <b>##clients## <a href="##selfstatus_clients##" title="View clients">clients</a></b>
 (<b><a href="##selfstatus_clientmap##" title="View clientmap">clientmap</a></b>)
 (<b>##proxies## of them are <a href="##selfstatus_proxies##" title="View proxies">proxies</a></b>),
 belonging to <b>##groups##</b> different
 <b><a href="##selfstatus_groups##" title="View groups">groups</a></b>. I can use
 <b>##jobtypes## <a href="##selfstatus_jobtypes##" title="View jobtypes">job types</a></b>,
 <b>##testcases## <a href="##selfstatus_testcases##" title="View testcases">test cases</a></b>, and 
 <b>##charsets## <a href="##selfstatus_charsets##" title="View charsets">char sets</a></b>. There are 
 <b>##users## <a href="##selfstatus_users##" title="View users">users</a></b> defined.
</p>

<p>
 My job list contains <b>##jobs##</b> jobs in
 <b>##cases## <a href="##selfstatus_cases##" title="View cases">cases</a></b>,
 <b>##tobedone##</b> of them are still
 running, <b>##done##</b> are done and <b>##suspended##</b> are suspended.
 I found <b>##results## <a href="##selfstatus_results##" title="View results">results</a></b>
 for all the jobs until now.
 There is a list of all the
 <b><a href="##selfstatus_chunks##">open chunks</a></b>.
</p>

<p>
Back to <b><a href="##selfstatus_main##">main status page</a></b>.
</p>

</div>
