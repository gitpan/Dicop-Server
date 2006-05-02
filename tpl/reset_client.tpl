
<h1><a class="h" href="##selfstatus_main##" title="Back to main">DiCoP</a> - Reset client ###id## - ##name##</h1>

<div class="text">

<p>
The form below will reset the client's speed, and remove all the cached
jobspeed values as well as the connect tracking, which will re-enable the
client to connect if it was blocked by the request-rate limit.
<br>
If you want to reset all clients, go to the
<a href="##selfstatus_clientmap##">clientmap page</a>.
</p>

##include_authform.inc##

<input type=hidden name="type" value="client">
<input type=hidden name="cmd" value="reset">
<input type=hidden name="id" value="##id##">

<input type=submit class="submit" name="submit" value="Reset client">
</form>

</div>

