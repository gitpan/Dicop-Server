
##include_menu_edit.inc##

<h1><a class="h" href="##selfstatus_main##">DiCoP</a> - Change ##type## ###id##</h1>

<div class="text">

##include_authform.inc##

<table class="edit">

##edit-object-fields##

</table>

<input type="hidden" name="cmd" value="change">
<input type="hidden" name="id" value="##id##">
<input type="hidden" name="type" value="##type##">
##carry##<input class="submit" type=submit name="submit" title="Click to submit the form" value="Submit changes">
<input class="reset" type=reset title="Click to reset the form" value="Reset form">
</form>

</div>

<h2><a name="help">Help</a></h2>

<div class="text">

<p>
##object-template-description##
</p>

<p>
##object-template-help##
</p>

</div>
