
use Dicop::Event;
use Dicop::Item;
use Dicop::Request;
use Dicop::Request::Pattern;

###########################################################################
# load request.def file

sub _load_patterns
  {
  my $patterns = [ Dicop::Item::from_file ( "../def/request.def", 'Dicop::Request::Pattern',) ];

  foreach my $pattern (@$patterns)
    {
    $pattern->_construct();
    # check for errors
    if ($pattern->error() ne '')
      {
      request Carp; croak($pattern->error());
      }
    }
  $patterns;
  }

sub _load_templates
  {
  my $file = "../def/objects.def";
  Dicop::Item::_load_templates( $file );
  }

# load messages and request patterns
Dicop::Event::load_messages("../msg/messages.txt");

$Dicop::Request::DEFAULT_PATTERNS = _load_patterns();

_load_templates();

1;
