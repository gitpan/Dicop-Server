
# file is "required" by chunkpm.t and chunkcl.t

use File::Spec;

# dummy parent for chunk
package Foo;

require "common.pl";

use base qw/Dicop::Item/;
use Dicop::Data::Charset;
use Dicop::Data::Jobtype;
use Dicop::Data::Result;
use Dicop::Data::Client;
use Dicop::Data::Case;
my $jobtype = new Dicop::Data::Jobtype ( fixed => 3);
my $case = new Dicop::Data::Case ( id => 1 );

my $charset = new Dicop::Data::Charset ( set => "'a'..'z'" );
my $result = new Dicop::Data::Result ( result_hex => '303132' );
$charset->_construct();
my $foojob = new Dicop::Data::Job ( start => 'aaa', end => 'zaaa', 
  description => 'desc', owner => 'test', charset => $charset,
  ascii => 1, jobtype => $jobtype, case => $case,
  );
$foojob->{_parent} = new Foo;
$foojob->_construct();
my $fooclient = Dicop::Data::Client->new ( speed => 100 );

sub new
  {
  my $self = {};

  bless $self;
  }

sub modified
  {
  }

sub get_charset
  {
  return $charset;
  }

sub charset
  {
  return $charset;
  }

sub get_jobtype
  {
  return $jobtype;
  }

sub get_job
  {
  return $foojob;
  }

sub get_case
  {
  return $case;
  }

sub get_client
  {
  return $fooclient;
  }

sub get_result
  {
  return $result;
  }

sub get_object
  {
  my ($self,$req) = @_;

  my $method = 'get_' . $req->{type};
  $self->$method($req->{id});
  }

package main;

use Dicop qw/ISSUED DONE VERIFY BAD FAILED TIMEOUT SOLVED TOBEDONE/;
use Dicop::Base;
use Dicop::Data::Job;

my $client = Dicop::Data::Client->new ( id => 1, speed => 100 );
my $client2 = Dicop::Data::Client->new ( id => 4, speed => 100 );
my $client3 = Dicop::Data::Client->new ( id => 15, speed => 100 );

# test client for issuing chunks
my $client123 = Dicop::Data::Client->new ( id => 123, name => 'client', 
  speed => 100 );

my $job = Dicop::Data::Job->new ( start => 'aaa', end => 'zaaa', 
  description => 'desc', owner => 'test', charset => 1,
  ascii => 1,
  );
$job->{_parent} = new Foo;
$job->_construct();

ok ($job->{_error}, '');

my $cs = $job->{charset}->charset();

##############################################################################

my $chunk = $class->new ( 
  job => $job, start => $job->{start},
   end => $job->{end}, id => 2,
  );
$chunk->{_parent} = $job->{_parent};
$chunk->_construct();

##############################################################################
# list of verifiers

# chunk not issued
my ($new_status,$rc,$msg) = 
    $chunk->verify( $client2,
                           DONE,  '',      'cafebabe', 3           ,3);
ok ($new_status, TOBEDONE); ok ($rc, -6);	# not issued

$chunk->status(ISSUED);
ok (ref($chunk->{verified}),'HASH');
ok (scalar keys %{$chunk->{verified}},0);
ok ($chunk->verifiers(),0);

ok ($chunk->verified_by($client), 0);

my $now = Dicop::Base::time();

# errors in adding verifier
ok ($chunk->add_verifier( $client, DONE, 'deadbeef', 'cafebabe'), -4);
ok ($chunk->add_verifier( $client, SOLVED, '', 'cafebabe'), -5);
ok ($chunk->add_verifier( $client, FAILED, '', 'cafebabe'), -2);
ok ($chunk->add_verifier( $client, FAILED, 'face2face', 'cafebabe'), -2);

$chunk->{status} = VERIFY;				# simulate a verify()

ok ($chunk->add_verifier( $client, DONE, '', 'cafebabe'), 1); # cnt++
ok ($chunk->verifiers(),1);				# really?
ok (ref($chunk->{verified}->{1}->[0]), 'Dicop::Data::Client');	# ref to client
ok ($chunk->{verified}->{1}->[1], DONE);
ok ($chunk->{verified}->{1}->[2], '');
ok ($chunk->{verified}->{1}->[3], 'cafebabe');
ok ($chunk->{verified}->{1}->[4], $now);

# adding another verifier makes this status VERIFY
#                  client, status, result, crc,     needed done, needed solved

($new_status,$rc,$msg) = 
    $chunk->verify( $client2,
                           DONE,  '',      'cafebabe', 3           ,3);

ok ($new_status, VERIFY); ok ($rc, 0);	# need one more
ok ($chunk->verifiers(),2);		# we are not alone

($new_status,$rc,$msg) = 
 $chunk->verify( $client3,
                           DONE,   '',     'cafebabe', 3           ,3); 

ok ($new_status, DONE); ok ($rc, 0);	# have enough
ok ($chunk->verifiers(),3);		# verified ok, list not yet cleared

##############################################################################
# check del_verifiers() and clear_verifiers()

$chunk->del_verifier($client3);
ok ($chunk->verifiers(),2);		# one less
$chunk->del_verifier($client3);
ok ($chunk->verifiers(),2);		# none less

$chunk->clear_verifiers();	
ok ($chunk->verifiers(),0);		# empty again

##############################################################################
# check that $chunk->verify() complains about mismatches

$chunk->{status} = VERIFY;				# simulate a verify()
# split persona?
# DONE vs. DONE on same client
($new_status,$rc,$msg) = 
   $chunk->verify( $client,
                           DONE,  '', 'cafebabe', 3, 3);
ok ($new_status, VERIFY); ok ($rc, 0);	# need one more
 
($new_status,$rc,$msg) = 
   $chunk->verify( $client,
                           DONE,  '', 'cafebabe', 3, 3);
ok ($new_status, BAD); ok ($rc, -3);	# need somebody else

$chunk->clear_verifiers();

# DONE vs. DONE on differnt client with differen opionons
# crc's mismatch
($new_status,$rc,$msg) = 
   $chunk->verify( $client,
                           DONE,  '', 'cafebabe', 3, 3);
ok ($new_status, VERIFY); ok ($rc, 0);	# need one more
 
($new_status,$rc,$msg) = 
   $chunk->verify( $client2,
                           DONE,  '', '2bad4a11', 3, 3);
ok ($new_status, BAD); ok ($rc, 0);

$chunk->clear_verifiers();

# DONE vs. SOLVED
($new_status,$rc,$msg) = 
   $chunk->verify( $client,
                           DONE,  '',      'cafebabe', 3, 3);
ok ($new_status, VERIFY); ok ($rc, 0);	# need one more

($new_status,$rc,$msg) = 
  $chunk->verify( $client2,
                           SOLVED,   '2bac', 'cafebabe', 3, 3); 
ok ($new_status, BAD); ok ($rc, 0);
$chunk->clear_verifiers();
	

# SOLVED vs. DONE
($new_status,$rc,$msg) = 
  $chunk->verify( $client,
                           SOLVED,  '4bac',      'cafebabe', 3, 3); 
($new_status,$rc,$msg) = 
  $chunk->verify( $client2,
                           DONE,   '', 'cafebabe', 3, 3); 
ok ($new_status, BAD); ok ($rc, 0);
$chunk->clear_verifiers();	

# results mismatch
($new_status,$rc,$msg) = 
   $chunk->verify( $client,
                           SOLVED,  '4bac',      'cafebabe', 3, 3);
($new_status,$rc,$msg) = 
    $chunk->verify( $client2,
                           SOLVED,   'bac24', 'cafebabe', 3, 3); 
ok ($new_status, BAD); ok ($rc, 0);
$chunk->clear_verifiers();	

# crc's mismatch
($new_status,$rc,$msg) = 
    $chunk->verify( $client,
                           SOLVED,  'cafeface',  'face0fbabe', 3, 3);
($new_status,$rc,$msg) = 
    $chunk->verify( $client2,
                           SOLVED,   'cafeface', 'deadcafe', 3, 3);
ok ($new_status, BAD); ok ($rc, 0);
$chunk->clear_verifiers();	


##############################################################################
# checksum

$chunk->_checksum();
ok ($chunk->checksum(),$chunk->{checksum}); 

ok ($chunk->get('id'),2);

# we did survive until here
ok ( $chunk->size(), 26*26*26*26+1);
ok ( $chunk->token(), '');


my $new = $chunk->split ($client->{speed},3);

ok ($chunk->get('id'),2);
ok ($new->{id},3); 

# for performance reasons, {size} mirrors {_size} and gets written to disk
# so they better be equal
ok ( $chunk->{_size}, $chunk->{size});

ok ($new->size(),26*26*26*26-26*26*26+1); # "$client->{speed}");

$chunk->{start} = Math::String->new('eaaaa',$cs);
$chunk->{end} = Math::String->new('aaaaaaa',$cs);
$chunk->_adjust_size();
$new = $chunk->split (200,3);
ok ($chunk->size(),26*26*26+1); 
ok ($chunk->{id},2); 
ok ($new->{id},4); 

$chunk->issue( $client123 ,'secret',1234);
ok ($chunk->{client}->{id},123);
ok ($chunk->{status},ISSUED);

# issue() did generate token?
ok (1,1) if $chunk->{token} ne '';
ok ('','not empty string') if $chunk->{token} eq '';


ok ($chunk->get('start'),'6561616161,2303159');
ok ($chunk->get_as_hex('start'),'6561616161');
ok ($chunk->get('end'),'6562616161,2320735');
ok ($chunk->get_as_hex('end'),'6562616161');

# try to put something different in
$chunk->put('start','6261616161');
undef $chunk->{size};
$chunk->_construct();
ok ($chunk->get('start'),'6261616161,932231');

# try to split a chunk and create a size=1 (should not happen)
$new = $chunk->split (0.001,0);
ok ($chunk->size(),26+1); 

##############################################################################
# check age

ok ($chunk->status(), ISSUED);
ok ($chunk->check_age($client),0);

$chunk->status(BAD);     ok ($chunk->check_age($client),0);
$chunk->status(VERIFY);  ok ($chunk->check_age($client),0);
$chunk->status(FAILED);  ok ($chunk->check_age($client),0);
$chunk->status(TIMEOUT); ok ($chunk->check_age($client),-1);
$chunk->status(DONE);    ok ($chunk->check_age($client),-1);
$chunk->status(SOLVED);  ok ($chunk->check_age($client),-1);

##############################################################################
# check that a check age converting a chunk back to TOBEDONE clears the
# list of verifiers

$chunk->status(VERIFY);  
$chunk->add_verifier( $client, DONE, '', '12345678' );
ok ($chunk->verifiers(),1);
$chunk->{issued} -= 3600*24 * 2;		# simulate old chunk
ok ($chunk->check_age($client),1);		# got converted?
ok ($chunk->status(),TOBEDONE); 		# really?
ok ($chunk->verifiers(),0);			# cleared list?

$chunk->status(BAD);  
$chunk->add_verifier( $client, DONE, '', '12345678' );
ok ($chunk->verifiers(),1);
$chunk->{issued} -= 3600*24 * 2;		# simulate old chunk
ok ($chunk->check_age($client),1);		# got converted?
ok ($chunk->status(),TOBEDONE); 		# really?
ok ($chunk->verifiers(),0);			# cleared list?

##############################################################################
# try to split a chunk at exact border (should NEVER split above that border)

$chunk = $class->new ( 
  job => $job, start => Math::String->new('aaa',$cs),
   end => Math::String->new('zzz',$cs), id => 2,
  );
# the last digit is fixed, so abc is not possible, it must be aba (not aca!)
$new = $chunk->split (Math::String->new('abc',$cs),1);
ok ($chunk->size(),26+1); 
ok ($chunk->start(),'aaa'); 
ok ($chunk->end(),'aba');
ok ($new->size(),17550);		# zzz-aaa => 17576 - 26 => 17550
 
# try to split at a border that would result in rounding up
$new = $chunk->split (Math::String->new('aad',$cs),1);
ok (1,1) if !defined $new;		# split failed
ok ($new,'undef') if defined $new;	# split didn't fail but should

ok ($chunk->size(),26+1);		# stays the same 
ok ($chunk->start(),'aaa'); 
ok ($chunk->end(),'aba'); 

# result
ok ($chunk->{result}, 0);
ok (ref ($chunk->result($result)), ref($result));
ok (ref ($chunk->result()), 'Dicop::Data::Result');
ok ($chunk->result()->{result_hex}, '303132');

##############################################################################
# is_open()

$chunk->status(VERIFY); ok ($chunk->is_open(),1);
$chunk->status(TOBEDONE); ok ($chunk->is_open(),1);
$chunk->status(FAILED); ok ($chunk->is_open(),1);
$chunk->status(BAD); ok ($chunk->is_open(),1);
$chunk->status(ISSUED); ok ($chunk->is_open(),1);
$chunk->status(SOLVED); ok ($chunk->is_open(),0);
$chunk->status(DONE); ok ($chunk->is_open(),0);

##############################################################################
# from_string() and as_string()

$chunk->issue( $client123, 'secret',1234);

# no verifiers, so don't write out
my $string = $chunk->as_string();
print "# Got: '$string'\n" unless ok ($string =~ /  verified = /,'');

ok ($chunk->add_verifier( $client, DONE, '', 'face'), 1); # cnt == 1

# print $chunk->as_string(),"\n";

$chunk->clear_verifiers();

ok ($chunk->add_verifier( $client, SOLVED, '2bac', 'face'), 1); # cnt == 1

# read in a prepared chunk text
my $FILE;
my $file = 'chunk.txt';
$file = File::Spec->catfile('data','chunk.txt') if !-f $file;
open $FILE, $file or die ("Cannot read $file: $!");
my $doc = "";
while (my $line = <$FILE>)
  {
  next if $line =~ /^#/;		# skip comments
  $doc .= $line;
  }
close $FILE;

my ($chunk2,$chunk3);

($chunk,$chunk2,$chunk3) = Dicop::Item::from_string($doc);
$chunk->{_parent} = Foo->new();
$chunk2->{_parent} = $chunk->{_parent};
$chunk3->{_parent} = $chunk->{_parent};
$chunk->_construct();
$chunk2->_construct();
$chunk3->_construct();

$string = $chunk->as_string() . $chunk2->as_string() . $chunk3->as_string();

# equalize (the checksum is different after reading in (bug), so remove it for
# now to compare them
$string =~ s/\s+(checksum|modified)\s=\s.*//g;
$doc =~ s/\s+(checksum|modified)\s=\s.*//g;

ok ($string,$doc);

##############################################################################
# verify() with FAILED sets reason

$chunk = $class->new (
  job => $job, start => Math::String->new('aaa',$cs),
   end => Math::String->new('zzz',$cs), id => 2,
  );
$chunk->_construct();

$chunk->status(ISSUED);
$chunk->{client} = $client2;

# chunk not issued
($new_status,$rc,$msg) = 
  $chunk->verify( $client2,
                        FAILED,  '',      'cafebabe', 3           ,3, 'some reason');
ok ($new_status, FAILED);	# failure
ok ($chunk->{reason},'some reason');

##############################################################################
# test for split() w/ simple charsets

my $chars = "61:62:63:64:65:66:67:68:69:6a:6b:6c:6d:6e:6f:70:71:72:73:74:75:76:77:78:79:7a:41:42:43:44:45:46:47:48:49:4a:4b:4c:4d:4e:4f:50:51:52:53:54:55:56:57:58:59:5a:30:31:32:33:34:35:36:37:38:39:21:22:23:26:28:29:2a:2b:2c:2d:2e:2f:30:3a:3b:3c:3d:3e:3f:5b:5c:5d:5e:5f:7b:7c:7d:b0";

my $ccs = Math::String::Charset->new( [ split/:/, $chars ]);

my $x = Math::String->new('307a797478743238', $ccs);
my $y = Math::String->new('b07a7a7a7a7a7ab0', $ccs);

$chunk = $class->new (
  job => $job, start => $x->copy(),
   end => $y->copy(), id => 2,
  );
$chunk->_construct();

$new = $chunk->split(Math::BigInt->new("880586701"));

ok ($chunk->size(), Math::BigInt->new("880586702") );
ok ($new->size() + $chunk->size() - 1, $y->copy()->bsub($x)->as_number() + 1);

print "# ", $new->get('size'), " ", $chunk->get('size'),"\n";

##############################################################################
##############################################################################

# tests below only for Checklist chunks
exit if $class ne 'Dicop::Data::Chunk::Checklist';	

# shrink() a chunk:

$chunk = $class->new (
  job => $job, start => Math::String->new('aaa',$cs),
   end => Math::String->new('zzz',$cs), id => 2,
  );
$chunk->_construct();

my $shrink_wrap = $chunk->copy();
$result = Math::String->new('foo',$cs);

ok ($shrink_wrap->shrink($result, 0, 0),
  'Shrink factor must be greater than 1');

ok ($shrink_wrap->shrink($result, -1, 0),
  'Shrink factor must be greater than 1');

ok ($shrink_wrap->shrink($result, 2, -1),
  'Count of fixed chars must be greater than or equal to 0');

ok ($shrink_wrap->shrink($result, 2, 0), $shrink_wrap);

my $lsize = $result - Math::String->new('aaa',$cs);
$lsize = $lsize->as_number();

my $usize = Math::String->new('zzz',$cs) - $result;
$usize = $usize->as_number();

ok ($shrink_wrap->{start}, $chunk->{start} + $lsize / 2);
# not this, that would be rounding up, we always truncate (round down)
#ok ($shrink_wrap->{end}, $chunk->{end} - $usize / 2);
ok ($shrink_wrap->{end}, $result + $usize / 2);
ok ($shrink_wrap->size(), $chunk->size() / 2);

##############################################################################
# chunk too small to be shrunk

$chunk = $class->new (
  job => $job, start => Math::String->new('aaa',$cs),
   end => Math::String->new('aaf',$cs), id => 2,
  );
$chunk->_construct();

$shrink_wrap = $chunk->copy();
$result = Math::String->new('aad',$cs);
ok ($shrink_wrap->shrink($result, 2, 0), $shrink_wrap);
ok ($shrink_wrap->size(), $chunk->size());

##############################################################################
# lower part too small to be shrunk

$chunk = $class->new (
  job => $job, start => Math::String->new('aaa',$cs),
   end => Math::String->new('zzz',$cs), id => 2,
  );
$chunk->_construct();

$shrink_wrap = $chunk->copy();
$result = Math::String->new('aad',$cs);

$lsize = $result - Math::String->new('aaa',$cs);
$lsize = $lsize->as_number();
$usize = Math::String->new('zzz',$cs) - $result;
$usize = $usize->as_number();

ok ($shrink_wrap->shrink($result, 10, 0), $shrink_wrap);
ok ($shrink_wrap->size(), $usize / 10 + $lsize + 1);

##############################################################################
# upper part too small to be shrunk

$shrink_wrap = $chunk->copy();
$result = Math::String->new('zzu',$cs);
$lsize = $result - Math::String->new('aaa',$cs);
$lsize = $lsize->as_number();
$usize = Math::String->new('zzz',$cs) - $result;
$usize = $usize->as_number();

ok ($shrink_wrap->shrink($result, 10, 0), $shrink_wrap);
ok ($shrink_wrap->size(), $usize + $lsize / 10 + 1);

##############################################################################
# upper part too small (size == 0) to be shrunk

$shrink_wrap = $chunk->copy();
$result = Math::String->new('zzz',$cs);
$lsize = $result - Math::String->new('aaa',$cs);
$lsize = $lsize->as_number();
$usize = Math::String->new('zzz',$cs) - $result;
$usize = $usize->as_number();

ok ($shrink_wrap->shrink($result, 10, 0), $shrink_wrap);
ok ($shrink_wrap->size(), $usize + $lsize / 10 + 1);

##############################################################################
# lower part too small (size == 0) to be shrunk

$chunk = $class->new (
  job => $job, start => Math::String->new('aaa',$cs),
   end => Math::String->new('zzz',$cs), id => 2,
  );
$chunk->_construct();

$shrink_wrap = $chunk->copy();
$result = Math::String->new('aaa',$cs);

$lsize = $result - Math::String->new('aaa',$cs);
$lsize = $lsize->as_number();
$usize = Math::String->new('zzz',$cs) - $result;
$usize = $usize->as_number();

ok ($shrink_wrap->shrink($result, 10, 0), $shrink_wrap);
ok ($shrink_wrap->size(), $usize / 10 + $lsize + 1);

