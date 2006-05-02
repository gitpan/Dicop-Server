
<h1><a class="h" href="##selfstatus_main##" title="Back to main">DiCoP</a> - Terminate ##name## (###id##)</h1>

<div class="text">

<p>
The form below will send (upon the next connect) a signal to the client to terminate
itself. This gives the client the chance to either terminate or to update itself and
then reconnect to the server.
<br>
If you want to terminate all clients, go to the
<a href="##selfstatus_clientmap##">clientmap page</a>.
</p>

##include_authform.inc##

<input type=hidden name="type" value="client">
<input type=hidden name="cmd" value="terminate">
<input type=hidden name="id" value="##id##">

<input type=submit class="submit" name="submit" value="Send terminate signal">
</form>

</div>

