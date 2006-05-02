<!-- template for style list with one template entry between start/end -->

<h1><a class="h" href="##selfstatus_main##" title="Back to main">DiCoP</a> - Styles</h1>

<div class="text">

<p style="float: left;">

<table style="float: left">

<tr>
 <th>Style Name</th>
</tr>

<!-- start -->
<tr>
<td><a href="##selfstatus_style##;style_##stylevalue##">##stylename##</a></td>
</tr>
<!-- end -->

</table>

</p>

<p style="float: left; margin-right: 1em;">

<table>

<tr>
 <th>Layout Name</th>
</tr>

##table2##

</table>

</p>

 <div style="margin: 0.5em;">
  <p>
  Select a color style on the left, and then combine it with a layout from the right table.
  </p>
  <p>
  Note: Some of the layout changes will not be visible on all browsers. Especially the rounded
  corners only work on Mozilla-based browsers.
  </p>
 </div>

<!-- extend the upper text paragraph below the style-selector tables -->

<hr class="pushdown">

</div>

<div class="clear"></div>

<div class="text">

<p>
Below are some sample elements that show you how the current style will look:
</p>

<p>
<input type="text" value="Entryfield">
<input class="submit" type="submit" title="Don't click me!">
</p>

<table>
  <tr>
    <th>Sample</th><th>Table</th>
  </tr>
    <td>Some text</td><td><a href="##self_statusmain##">123</a></td>
  </tr>
</table>

<table>
  <tr>
    <td colspan="3" class="entryfieldname1">Enter:</td><td class="entryfield1"><input type="text" value="Entryfield"></td>
   <td class="editfieldhelp">
    Some help text.
   </td>
  </tr>

  <tr>
   <td class="indend"></td>
   <td class="editfieldname1" colspan=2>Number:</td>
   <td class="editfield" colspan=1>
    <input type=text name="addcase-name" value="" size=32 maxlength=64>
   </td>
   <td class="editfieldhelp">
    Some help text.
   </td>
  </tr>

</table>

<ul>
  <li>Item 1
  <li>Item 2
</ul>

</div>

