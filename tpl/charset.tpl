<!-- details for one charset -->

##include_menu_object.inc##

<h1><a class="h" href="##selfstatus_main##">DiCoP</a> - Charset ###id##</h1>

<div class="text">

<p>
Charset ##id## (<i>##description##</i>) is a <b>##type##</b> charset. See <a href="#help">below</a>
for an explanation on what that means. Here is the definition of this character
set:
</p>

<pre>
##set##
</pre>

</div>

<h2>String lengths and character set size</h2>

<div class="text">

<p>
Below are the first and last strings of different lengths
to show what typical strings for this character set look like. Also, for
each string length, the total amount of different strings with that length
under this characterset is listed. See <a href="#help">below</a> for more
explanations. 
</p>

<pre>
##stringlengths##
</pre>

</div>

<h2>Sample strings</h2>

<div class="text">

<p>
If you entered some example strings, here is a list showing whether they
would be valid under this character set, and if so, what their respective
number would be:
</p>

<p>
Valid sample strings and their representations as number:
</p>

<pre>
##validsamples##
</pre>

<p>
Invalid strings (under this character set):
</p>

<pre>
##invalidsamples##
</pre>

<p>
Enter here some sample strings and press the "Update" button to see if they
are valid or not under this charset. Note: If you wish to enter strings
that start with '0x' or contain characters other than letters, numbers,
spaces and a few other special characters (e.g., a string containing a newline,
a null (0x00) or other specialspecial characters), then enter the string as
hex in the form '0xdeadbeaf'.
</p>

<form method=POST action="##self##">

<textarea rows=10 cols=38 name="samples">##samples##</textarea>

<input type=hidden name="style" value="##style##">
<input type=hidden name="cmd" value="status">
<input type=hidden name="type" value="charset">
<input type=hidden name="id" value="##id##">
<input type=submit class="submit" name="submit" value="Update!">
</form>

</div>

<h2>Help</h2>

<div class="text">

<p>
Some more help should be written here....
</p>

<p>
Back to <a href="##selfstatus_main##">main</a> status page.
</p>

</div>
