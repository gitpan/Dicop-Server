
<table class="input">

<tr><td class="editfieldname">Type:</td>
<td class="editfield">
<select name="type">
<option value="cases">Cases</option>
<option value="charsets">Character sets</option>
<option value="clients">Clients</option>
<option value="groups">Groups</option>
<option value="jobs">Jobs</option>
<option value="jobtypes">Jobtypes</option>
<option value="results">Results</option>
<option value="proxies">Proxies</option>
<option value="testcases">Testcases</option>
<option value="users">User</option>
</select>

</td><td>
<font size=-1>
Select the type of the object to search.
</font>
</td>
</tr>

<tr><td class="editfieldname">ID:</td>
<td class="editfield">
<input type=text value="ANY" name="id">

</td><td>
<font size=-1>
Type an ID number or ANY when all IDs should match. The match will always
be exact.
</font>
</td>
</tr>

<tr><td class="editfieldname">IP:</td>
<td class="editfield">
<input type=text value="ANY" name="ip">

</td><td>
<font size=-1>
Type an IP number or ANY when all IPs should match. The match will always
be exact. This is only usefull for searching clients, other objects don't
have an IP field, so they will never match.
</font>
</td>
</tr>

<tr><td class="editfieldname">Name:</td>
<td class="editfield">
<input type=text value="ANY" name="name">

</td><td>
<font size=-1>
Type a string or ANY when all names should match. This will always also match
partial names.
</font>
</td>
</tr>

<tr><td class="editfieldname">Description:</td>
<td class="editfield">
<input type=text value="ANY" name="description">

</td><td>
<font size=-1>
Type a string or ANY when all descriptions should match. This will always also
match partial strings in the description field.
</font>
</td>
</tr>

<tr><td class="editfieldname">Case&nbsp;sensitivity:</td>
<td class="editfield">
<select name="case">
<option value="0">case insensitive match</option>
<option value="1">case sensitive match</option>
</select>

</td><td>
<font size=-1>
Select the type of the object to search.
</font>
</td>
</tr>


</table>

<p>
<input type=hidden name="cmd" value="search">
<input type=submit class="submit" name="submit" value="##param0##">
</p>

</form>

