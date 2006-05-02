
##include_menu_help.inc##

<h1><a class="h" href="##selfstatus_main##">DiCoP</a> - Add a ##type##</h1>

<div class="text">

<p>
Please fill in all the fields and then press the button to add a ##type## to the cluster.
Refer to the <a href="#help">help</a> below if you are unsure.
</p>

##include_authform.inc##

<table class="edit">

##add-object-fields##

</table>

##object-template-include##

<input type=hidden name="cmd" value="add">
<input type=hidden name="type" value="##type##">
<input class="submit" class="submit" type=submit name="submit" title="Click to submit the form and add the ##type##" value="Add ##type##">
<input class="reset" class="reset" type=reset title="Click to clear the form and reset all values" value="Reset form">
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
