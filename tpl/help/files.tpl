

<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP</a> - Files</h1>

<!-- topic: File structure of the server/client. -->

<div class="text">

<p>
File structure of the server/client.
</p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#server">SERVER</a></li>
	<ul>

		<li><a href="#overview">OVERVIEW</a></li>
		<li><a href="#templates">Templates</a></li>
		<li><a href="#styles">Styles</a></li>
		<li><a href="#help">Help</a></li>
		<li><a href="#worker">Worker</a></li>
		<li><a href="#dictionaries">Dictionaries</a></li>
		<li><a href="#data_files">Data files</a></li>
	</ul>

	<li><a href="#client">CLIENT</a></li>
	<ul>

		<li><a href="#worker_files">Worker files</a></li>
		<li><a href="#charset_definitions">Charset definitions</a></li>
		<li><a href="#dictionaries">Dictionaries</a></li>
		<li><a href="#log_files">Log files</a></li>
		<li><a href="#target_files_files">Target files files</a></li>
		<li><a href="#job_description_files">Job description files</a></li>
		<li><a href="#chunk_job_description_files__cdf_or_jdf_">Chunk/Job Description Files (CDF or JDF)</a></li>
	</ul>

	<li><a href="#author">AUTHOR</a></li>
</ul>
</div>


<p>Last update: 2004-09-15</p>

</div>



<h2><a name="server">SERVER</a></h2>

<div class="text">



</div>

<h3><a name="overview">OVERVIEW</a></h3>

<div class="text">

<p>The typical server setup looks like this:</p>

<pre>
        tpl/                    HTML templates
        tpl/styles/             styles for HTML output
        tpl/mail/               email template files
        tpl/help/               HTML versions of the /doc POD files
        doc/                    documentation in pod format
        build/                  scripts related to building the
                                distribution and HTML help
        worker/                 the worker files
        target/                 job targets
        target/dictionaries     dictionary files
        target/data             Job/Chunk description files (dynamically
                                created by the server)
        config/                 configuration files
        lib/                    source code (the program itself)
        logs/                   log files are stored here
        scripts/                scripts to convert input files to
                                target hashes or target files
        msg/                    message strings in various languages
        def/                    Various definition files, f. i. for
                                the valid requests, objects etc
        
Note that several of the directorie names can be changed through the config
file settings. This includes f.i. the log and script directories.</pre>



</div>

<h3><a name="templates">Templates</a></h3>

<div class="text">

<p>The template directory contains HTML template files, which will be read
in and filled with information for each request.</p>

<p>See also <a href="#styles">styles</a>.</p>



</div>

<h3><a name="styles">Styles</a></h3>

<div class="text">

<p>Under <code>tpl/styles</code> are the various GUI styles that can be selected to change
to look of the web interface. Files inside these directories override the
files in <code>tpl/</code>, e.g. they will be prefered over the normal version in
<code>tpl/</code> if present in the current style directory.</p>



</div>

<h3><a name="help">Help</a></h3>

<div class="text">

<p>The HTML versions of the .pod files were created at build-time and are located
under <code>tpl/help/</code>.</p>

<p>To re-generate them, you can use the scripts provided in the <code>build/</code>
directory.</p>



</div>

<h3><a name="worker">Worker</a></h3>

<div class="text">

<p>The default directory for the worker files is <code>worker</code>. This can be changed
in the configuration file <code>server.cfg</code>, although a differently named
directory doe currently not work properly - it must start with <code>worker/</code>!</p>

<p>For each platform/architecture exists one directory in the worker directory:</p>

<pre>
        worker/linux/
        worker/mswin32/
        etc</pre>

<p>The worker files are then located in these directories.</p>

<p>Other directories under each architecture directory can contain files for
sub-architectures. For instance:</p>

<pre>
        worker/linux/i386/</pre>

<p>Could contain files that should be server to clients reporting in as
<code>linux-i386</code>. These override the normal files, so if a file does not
exist in <code>worker/architecture/sub-arch/</code> then it will be served from
<code>worker/architecture</code> as a fallback.</p>



</div>

<h3><a name="dictionaries">Dictionaries</a></h3>

<div class="text">

<p>Each dictionary charset is tied to a dictionary file. These dictionary files
are located in <code>target/dictionaries/</code>.</p>



</div>

<h3><a name="data_files">Data files</a></h3>

<div class="text">

<p>The default directory for the server main data files is <code>data</code>. This is the
offline storage of the server's memory - e.g. the current state of anything.</p>

<p>This can be changed in the configuration file <code>server.cfg</code>.</p>

<p>The following file names are used per default. This can be overwritten in the
<code>server.cfg</code> file as well:</p>

<pre>
        cases.lst
        charsets.lst
        clients.lst
        groups.lst
        jobs.lst
        jobtypes.lst
        proxies.lst
        results.lst
        testcases.lst
        users.lst               List of user accounts (for administation)</pre>



</div>

<h2><a name="client">CLIENT</a></h2>

<div class="text">

<p>The typical client setup looks like this:</p>

<pre>
        client                  The client in itself
        lib/                    The libraries the client uses
        msg/                    The messages the client outputs in different
                                languages
        def/                    Definition files used by the client
        config/client.cfg       Client config file</pre>

<p>In addition, the following directories must exist with write permission for the
user and group the client is running under, because the client will be storing
some things in them.</p>

<pre>
        worker/                 Worker files
        target/                 Target files are stored here
        cache/                  Certain files are cached here (f.i. by wget)
        log/                    The log files in case of errors.</pre>

<p>It is safe to delete anything when the client is not running in these
directories (you might want to keep the logfiles, though), because everything
that is missing will be downloaded by the client automatically.</p>



</div>

<h3><a name="worker_files">Worker files</a></h3>

<div class="text">

<p>Just as with the server, the workers are stored inside the <code>worker/</code>
directory.  Each architecture get's its own subdirectory, so your client will
typically store the workers inside of only one subdirectory. Some of the known
archictures are:</p>

<pre>
        linux
        mswin32
        os2
        armv4l
        darwin
        solaris</pre>

<p>If a directory for the current archictecture the client is running on does not
exist, it will be created.</p>

<p>Sub-architecture directories will not be used by the client, the client will
store files from them in the architecture directory directly as to override
the files there.</p>



</div>

<h3><a name="charset_definitions">Charset definitions</a></h3>

<div class="text">

<p>Charset definitions are usually stored in a file called <code>worker/charsets.def</code>.</p>



</div>

<h3><a name="dictionaries">Dictionaries</a></h3>

<div class="text">

<p>Each dictionary charset is tied to a dictionary file. These dictionary files
are downloaded and stored by the client in <code>target/dictionaries/</code>.</p>



</div>

<h3><a name="log_files">Log files</a></h3>

<div class="text">

<p>The client creates a logfile named <code>client_ID.log</code>, where ID is replaced
with the ID the client is currently running under (see commandline option
<code>--id</code> in CLient.pod). When the initialization of the client failes,
especially when it got no ID, then it will try to write an error log to the
file <code>client.log</code>.</p>



</div>

<h3><a name="target_files_files">Target files files</a></h3>

<div class="text">

<p>Each job might have zero or more target files. These are files that contain
additional info about that particular job. They are typical stored in the
<code>target/</code> directory and are named like:</p>

<pre>
        job_123.tgt</pre>

<p>Where 123 is the ID of the job.</p>



</div>

<h3><a name="job_description_files">Job description files</a></h3>

<div class="text">

<p>Additional data about a job (like the prefix and dictionary to use etc) were
stored in a file named like:</p>

<pre>
        target/123.set</pre>

<p>where 123 is the ID of the job. These files were automatically creatred by the
server and downloaded also automatically by the client.</p>



</div>

<h3><a name="chunk_job_description_files__cdf_or_jdf_">Chunk/Job Description Files (CDF or JDF)</a></h3>

<div class="text">

<p>Additional data about a particular chunk (like the prefix for each password,
a dictionary to use, or some extra data etc) are stored in a file named like:</p>

<p>Chunk description file:
</p>

<pre>

        target/data/2/2-2.txt</pre>

<p>Job description file:
</p>

<pre>

        target/data/2/2.set</pre>

<p>These files are created by the server, automatically downloaded by the client
and, in case of a CDF, are deleted after the chunk has been processed.</p>

<p>Here is an example file:</p>

<pre>
        ## This file was automatically generated. Do not edit.
        ## Chunk description file for job 3, chunk 2.
        charset_id=222
        image_file=&quot;target/images/image_3_2.img&quot;
        image_type=0
        extract_set_id=2
        start=3
        end=11
        password_prefix=666f6f626172
        target=4142434445</pre>

<p>For a full specification of the contents of these files, see <code>doc/Config.pod</code>
in the <code>Dicop::Workeframe</code> package which you can find at our web site.</p>



</div>

<h2><a name="author">AUTHOR</a></h2>

<div class="text">

<p>(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004</p>

<p>DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.</p>

<p>See the file LICENSE or <a href="http://www.bsi.bund.de/">http://www.bsi.bund.de/</a> for more information.

</p>



</div>


