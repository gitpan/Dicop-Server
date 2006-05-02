

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Objects</h1>

<!-- topic: Overview over the objects and data structures used in Dicop::Server -->

<div class="text">

<p>
Overview over the objects and data structures used in Dicop::Server
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#overview">OVERVIEW</a></li>
	<ul>

		<li><a href="#arrays_vs__hashes">Arrays vs. Hashes</a></li>
		<li><a href="#caches">Caches</a></li>
		<li><a href="#general_layout">General layout</a></li>
	</ul>

	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>Last update: 2004-06-22</p>

</div>



<h2><a name="overview">OVERVIEW</a></h2>

<div class="text">

<p>This describes the internal object representation and data structure layout in
a Dicop::Server from v3.00 onwards. This document is meant for developers.</p>



</div>

<h3><a name="arrays_vs__hashes">Arrays vs. Hashes</a></h3>

<div class="text">

<p>There are two fundamentally different ways to stores objects: arrays and hashes.
These corrospondend to the data structures from Perl with the same name.</p>

<p>A hash is organized on a key. In Dicop hashes are usually keyed on the object
ID. This allows for easy access to an object if its ID is known - and it also
creates the restriction that each ID must be unique. The disadvantage is that
it is not very easy to impose a certain order on the objects in the hash,
unless they can be sorted on one field (like the ID, name etc).</p>

<p>An array is simple a list of things. While this imposes automatically an order,
it does also allow duplicates and makes finding an object harder.</p>



</div>

<h3><a name="caches">Caches</a></h3>

<div class="text">

<p>There is also a container class called Dicop::Cache. It contains objects indexed
by a field (usually the ID), but also can impose a maximum number of objects
contained in the cache, as well as a maximum age of objects. Their age is
measured from the time they were last added to the cache, or last retrieved
from it.</p>



</div>

<h3><a name="general_layout">General layout</a></h3>

<div class="text">

<p>The top-most object is <code>Dicop::Data</code> itself. It is a singleton and contains
hashes of objects as:</p>

<pre>
        Dicop::Data::Jobtype
        Dicop::Data::Testcase
        Dicop::Data::Charset
        Dicop::Data::Client
        Dicop::Data::Proxy
        Dicop::Data::Group
        Dicop::Data::Case</pre>

<p>XXX TODO: make a testcase a list of jobtype?</p>

<p>The most important data structure is a list of <code>Dicop::Data::Case</code> objects, organized
in a hash:</p>

<pre>
  +---------+
  | Data    |
  +---------+
       |
       +------------+------------+----- ...
       |            |            |
       v            v            v 
  +---------+  +---------+  +---------+    
  | Case #1 |  | Case #1 |  | Case #3 | ...
  +---------+  +---------+  +---------+</pre>

<p>Each of these cases contains a list of <code>Dicop::Data::Job</code> objects, also organized
in a hash.</p>

<pre>
  +---------+
  | Case #1 | ...
  +---------+
       |
       +------------+------------+----- ...
       |            |            |
       v            v            v 
  +---------+  +---------+  +---------+    
  | Job #1  |  | Job #2  |  | Job #3  | ...
  +---------+  +---------+  +---------+</pre>

<p>Each job in turn contains a list of <code>Dicop::Data::Task</code> objects. These are stored
in an array, because their ordering is important:</p>

<pre>
  +---------+
  | Data    |
  +---------+
       |
       +------ ...
       |
       v
  +---------+
  | Case #1 |
  +---------+
       |
       +----- ...
       |
       v
  +---------+      +---------+---------+---------+
  | Job #1  | --&gt;  | Task #0 | Task #1 | Task #3 |...
  +---------+      +---------+---------+---------+</pre>

<p>For each job, only one task is active and in the TOBEDONE state. The tasks
before it are either in the FAILED, SUSPENDED or SOLVED state, while the tasks
after it are in the WAITING state. When one task is finished (solved, failed,
or suspended), the next waiting task will be set to TOBEDONE.</p>

<p>Each task in turn contains a list of <code>Dicop::Data::Chunk</code> objects. These are
also stored in an array, because their ordering is important:</p>

<pre>
  +---------+
  | Data    |
  +---------+
       |
       +------ ...
       |
       v
  +---------+
  | Case #1 |
  +---------+
       |
       +----- ...
       |
       v
  +---------+      +---------+
  | Job #1  | --&gt;  | Task #0 | ...
  +---------+      +---------+
                        |
                        v
                   +----------+----------+----------+
                   | Chunk #0 | Chunk #1 | Chunk #3 |...
                   +----------+----------+----------+</pre>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.</p>



</div>


