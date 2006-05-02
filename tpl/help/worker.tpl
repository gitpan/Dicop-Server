

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Worker</h1>

<!-- topic: The workers started by the client -->

<div class="text">

<p>
The workers started by the client
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#overview">OVERVIEW</a></li>
	<li><a href="#commandline_arguments">COMMAND-LINE ARGUMENTS</a></li>
	<ul>

		<li><a href="#chunk_description_file__cdf__as_the_only_parameter">Chunk Description File (CDF) as the only parameter</a></li>
		<li><a href="#job_description_file__jdf__as_the_set_parameter">Job Description File (JDF) as the set parameter</a></li>
		<li><a href="#charsets_def">charsets.def</a></li>
	</ul>

	<li><a href="#ouput">OUPUT</a></li>
	<ul>

		<li><a href="#stopcode">Stopcode</a></li>
		<li><a href="#crc">CRC</a></li>
		<li><a href="#examples">Examples</a></li>
	</ul>

	<li><a href="#errors">ERRORS</a></li>
	<li><a href="#exit_code">EXIT CODE</a></li>
	<li><a href="#additional_files">ADDITIONAL FILES</a></li>
	<li><a href="#developing_new_workers">DEVELOPING NEW WORKERS</a></li>
	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>Last update: 2004-09-14</p>

</div>



<h2><a name="overview">OVERVIEW</a></h2>

<div class="text">

<p>A <code>worker</code> is a command-line program, written usually in C or assembler
for maximum speed. It will check each key in a given chunk (small piece
of keyspace) against a target (hash or file with target information),
and determine whether a key in the given range is a solution to the
problem at hand, or not.</p>



</div>

<h2><a name="commandline_arguments">COMMAND-LINE ARGUMENTS</a></h2>

<div class="text">

<p>The worker expects the following arguments on the commandline in that order:</p>

<pre>
        start           start password in hexify
        end             end password in hexify
        target          target key/bytes in hexify (for comparing)
        set             charset number
        timeout         (optional) timeout in seconds
        debug           (optional) Output debug flag</pre>

<p>Here is an example:</p>

<pre>
        worker/linux/test 41414141 42414141 41424344 1 360</pre>

<p>The target can also be file name like <code>../../target/test.tgt</code>.</p>



</div>

<h3><a name="chunk_description_file__cdf__as_the_only_parameter">Chunk Description File (CDF) as the only parameter</a></h3>

<div class="text">

<p>Alternatively, the worker get's only one parameter on the commandline,
the filename of a so-called chunk description file. This is a small
textfile containing all the options and can be read with the apropriate
API function in the workerframe, respectively, if you use the workerframe,
will be read automatically for you.</p>

<p>Here is an example (assuming we are in <code>/worker/architecture</code>):</p>

<pre>
        ./test ../../target/chunk-1-2.txt</pre>



</div>

<h3><a name="job_description_file__jdf__as_the_set_parameter">Job Description File (JDF) as the set parameter</a></h3>

<div class="text">

<p>There is also a third way extra options can be passed to the worker.
When the charset was not a plain number, but a filename like <code>2.set</code>, then
the worker read in that file and got extra charset parameters from this file.</p>

<p>Example:</p>

<pre>
        ./test 41414141 42414141 41424344 ../../target/data/2/2.set 360</pre>

<p>If extra charset parameters are necessary (like a fixed prefix etc), but these
parameters do not change over the course of a job, then the server will create
a job description file.</p>

<p>Note: The advantage of a JDF over a CDF is that the latter needs to be
created and downloaded for each chunk. However, the only cases were a JDF is
really possible are a simple or grouped charset with a fixed prefix or a normal
job with extra params. All other cases (especially dictionary/extract charsets)
make a CDF necessary due to varying parameters (file offsets etc) on a
per-chunk basis.</p>



</div>

<h3><a name="charsets_def">charsets.def</a></h3>

<div class="text">

<p>The worker also expects a file called charsets.def in it's own directory
or one directory up. This file must contain the character set
definitons. This file is usually generated by the server, and then
downloaded by the client for the worker.</p>



</div>

<h2><a name="ouput">OUPUT</a></h2>

<div class="text">

<p><strong>Note:</strong> It is much easier to develop a conformant worker by using the
provided framework, the so-called Dicop-Workerframe. By using the
framework, you don't need to worry about the worker's input and
output at all. See <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.
</p>

<pre>

The worker has to output it's finding to STDOUT in the following form:

        Last tested password in hex was 'ABCD'
        CRC is 'U'
        Stopcode is 'X'</pre>

<p>All other output will be ignored by the client. Make sure that you do not
output great amounts of data (for instant for debugging), since the client
will collect all of it before parsing the output. A few Kbyte are okay,
though.</p>

<p>In case of errors, the error output should be detailed as possible and go to
STDOUT, too. Output to STDERR is visible on the console the client is
running, but will be otherwise ignored. This means f.i. it will not be
uploaded to the server, so you will not see it on the client's status page
there!</p>



</div>

<h3><a name="stopcode">Stopcode</a></h3>

<div class="text">

<p>The stopcode (denoted with <code>X</code> above) should be 0, 1, 2 or 3, depending on
result, and <code>ABCD</code> is an (optional) password that was found by the worker,
printed as hexstring without the leading 0x.</p>

<p>Explanation of code:</p>

<pre>
        0               found nothing, stepped through all pwd's
        1               found a result
        2               timeout
        3               some error prevented the worker from starting/working</pre>

<p>In case 0 and 3, password is a dummy (usually, but not neccessarily last
password in chunk). In case 1 the password must be the the actual result and
in case 2 the last password checked before the timeout occured.</p>

<p>If the proper stopcode output is missing, the client will assume an error,
e.g. if the worker failed to load or output anything at all.</p>



</div>

<h3><a name="crc">CRC</a></h3>

<div class="text">

<p>The CRC is a code computed on the actual keyspace the worker covered, in hex.
You can use the appropriate API function in the Workerframe to computer it.</p>

<p>If your worker is not able to compute a CRC, it should output <code>CRC is '0'</code>.</p>

<p>The CRC is basically a POWD (Proof Of Work Done) - e.g. something which 
is nowadays called sometimes a <code>hashcash</code>. It should be only computable if
you step through each key in the keyspace, e.g. hard to compute without
actually doing the work.</p>

<p>Summing up all the keys in the keyspace is not hard, but for instance summing
up all the first eight bytes of plaintexts decrypted by each key in the
keyspace, and then hashing the result would be hard to replicate.</p>



</div>

<h3><a name="examples">Examples</a></h3>

<div class="text">

<p>Didn't find a result:</p>

<pre>
        Last tested password in hex was '41424344'
        CRC is 'cafe'
        Stopcode is '0'</pre>

<p>Found a result:</p>

<pre>
        Last tested password in hex was '41424345'
        CRC is '1239'
        Stopcode is '1'</pre>

<p>Timeout:</p>

<pre>
        Last tested password in hex was '41424347'
        CRC is 'deadbeef'
        Stopcode is '2'</pre>

<p>Error:</p>

<pre>
        Could not load foo - aborting.
        Last tested password in hex was '41424347'
        CRC is '0'
        Stopcode is '3'</pre>

<p>Another example for an error:</p>

<pre>
        Could not load foo - aborting.</pre>



</div>

<h2><a name="errors">ERRORS</a></h2>

<div class="text">

<p>Upon error, the worker should either output a stopcode of '3' or no stopcode
at all.</p>



</div>

<h2><a name="exit_code">EXIT CODE</a></h2>

<div class="text">

<p>The exit code from the worker should be as follows:</p>

<pre>
        0               no password found
        1               password found or timeout occured
        &gt;1              some error occured</pre>



</div>

<h2><a name="additional_files">ADDITIONAL FILES</a></h2>

<div class="text">

<p>Apart from the target file, the worker might need additional files. These
should be searched in the following paths, in that order:</p>

<pre>
        ./              same dir as the worker
        ../             one up
        ../all/         additional platform independend worker files</pre>

<p>This assumes that the current working directory is the directory where
the worker is in. This will be true when the worker is started either
manually or by the client.</p>

<p>Target files will be always given with the correct path to the worker, so
the worker need not to search around for them.</p>



</div>

<h2><a name="developing_new_workers">DEVELOPING NEW WORKERS</a></h2>

<div class="text">

<p>We strongly suggest you use the framework provided by us (called
Dicop-Workerframe) to develop new workers, this makes it much easier and
contains already anything you need.</p>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.</p>



</div>

