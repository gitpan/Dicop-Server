use ExtUtils::MakeMaker;
require 5.008003;	# we need at least Perl v5.8.3
use strict;
use lib 'lib';          # if we bundled some modules with the
                        # distribution, try to find these first
                        # (otherwise old core modules would crop up)

use Dicop;		# for VERSION and BUILD, and base_version

# SSL does currently not work, so no need to check:

# check that we have SSL support:
#my $ssl = 0;
#eval { require IO::Socket::SSL; };
#if (defined $IO::Socket::SSL::VERSION)
#  {
#  $ssl++;
#  $ssl ++ if $IO::Socket::SSL::VERSION > 0.95;
#  }
#
#if ($ssl < 2)
#  {
#  warn ("*********** Warning:\n");
#  warn ("  You do not seem to have IO::Socket::SSL installed. SSL support will not be available.\n")
#    if $ssl == 0;
#  warn ("  Need at least IO::Socket::SSL v0.95 for proper SSL support, but found only v$IO::Socket::SSL::VERSION.\n")
#    if $ssl == 1;
#  warn ("  You need to install the latest version of IO::Socket::SLL from http://search.cpan.org/\n"); 
#  sleep(5);
#  }

# check that we have debug support
my $debug = 0;
eval { require Devel::Size; };
if (defined $Devel::Size::VERSION)
  {
  $debug++;
  }
eval { require Devel::Leak; };
if (defined $Devel::Leak::VERSION)
  {
  $debug++;
  }

if ($debug < 2)
  {
  warn ("*********** Warning:\n");
  warn ("  You do not seem to have Devel::Leak or Devel::Size installed. Debug support will not be available.\n");
  warn ("  You need to install the latest version of Devel::Size and Devel::Leak from http://search.cpan.org/\n"); 
  sleep(5);
  }

#############################################################################

use Dicop;					# for VERSION and BUILD
my $version = $Dicop::VERSION;
# for releases, omit the BETA VERSION
$version .= "_$Dicop::BUILD" if $Dicop::BUILD > 0;

WriteMakefile(
    'NAME'		=> 'Dicop-Server',
    'VERSION'           => $version,
    'PREREQ_FATAL'	=> 1, 
    'PREREQ_PM'		=> { 
		'Dicop::Base' => 3.02,
		'Digest::MD5' => 2.09,
		'File::Spec' => 0.82,
		'Mail::Sendmail' => 0.77,

# we need HTTP::Request, which means we need libwww and
# thus also HTML::Parser, which in turn needs HTML::Tagset

		'HTML::Tagset' => 3.03,
		'HTTP::Request' => 1.24,
		'Linux::Cpuinfo' => 1.7,
		'Math::BigInt' => 1.77,
		'Math::String' => 1.27,
		'Math::String::Charset::Wordlist' => 0.07,
		'Net::Server' => 0.86,
		'Test::Simple' => 0.47,
		'Time::HiRes' => 1.2,
    },
    'test'		=> { TESTS => 't/*.t t/data/*.t' },
);

my $ver = Dicop->base_version();

warn ("\n *** Warning: Need at least Dicop::Base $Dicop::BASE_MIN_VER, but got only $ver! ****\n\n") unless
  $ver >= $Dicop::BASE_MIN_VER;

#############################################################################
# test that if Math::BigInt::GMP is installed, it is up-to-date:

eval "require Math::BigInt lib => 'GMP';";

my $c = Math::BigInt->config();
if ($c->{lib} eq 'Math::BigInt::GMP' && ($c->{lib_version} < 1.18))
  {
  die ("Need at least Math::BigInt::GMP v1.18, but got only $c->{lib_version}. Please upgrade!\n");
  }

#############################################################################
# all done

1;

#############################################################################
# write META.yml

sub MY::metafile {
  package MY;
  my $self = shift;
  if (!eval { require YAML; 1 })
  {
    warn ("For developers: YAML not installed, 'make dist' will not override META.yml");
    return $self->SUPER::metafile_target(@_);
  };

  require YAML::Node;
  my $node = YAML::Node->new({});

  $node->{name}                 = $self->{DISTNAME};
  $node->{version}              = $self->{VERSION};
  $node->{version_from}         = 'lib/Dicop.pm';
  $node->{license}              = 'gpl';
  $node->{distribution_type}    = 'module';
  $node->{generated_by}         = "$self->{DISTNAME} version $self->{VERSION}";
  $node->{installdirs}          = 'none';
  $node->{requires}             = $self->{PREREQ_PM};

  my $dump = YAML::Dump( $node );

  $dump =~ s/^(.*)$/\t\$(NOECHO) \$(ECHO) "$1" >>META.yml/gm;
  $dump =~ s/>>META\.yml/>META.yml/;

  return "metafile:\n$dump";
}


