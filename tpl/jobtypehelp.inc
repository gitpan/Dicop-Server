
<a name="help"></a>
<h2>Help</h2>

<div class="text">

<p>
The relative speed is used to choose the correct chunksize for jobs of this
type. To determine it, run the worker for this jobtype and enter the average keys per second it
does.
<br>
Average here means the average over all your (expected) clients. If all your client's
are of the same type, this is easy, just pick one of them to test it. If you have
a lot of clients with different speeds, pick something average, e.g. if you expect
a 486 and a 686 to work in the cluster, benchmark a 585 client.
</p>

<p>
Here is an example:
</p>

<pre>
bash# time worker/linux/newtype 65656565 656565656565 65 1
</pre>

<p>
Choose a set of parameters that allows exact timing while not taking forever. For
instance, it should run for at least 10 seconds, but not more than a minute.
<br>
After the worker completed, it will print out how many keys per second it
did. Enter this value (round it to an integer with approximately 3 digits,
e.g. "1234.567" would become "1230", and so on)
</p>

</div>
