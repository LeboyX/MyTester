#!perl
package MyTester::ExecEx;
use 5.010;
use Moose;
use IPC::Run::Timer;

use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use MyTester::ExecFlag;
use MyTester::File;

use Carp;

use Data::Dumper;

use IPC::Run qw(harness timeout);

use File::Which;

use TryCatch;

################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

has 'cmd' => (
   isa => 'Str',
   is => 'rw',
   required => 1,
   trigger => sub {
      my ($self, $val) = @_;
      croak "'$val' cannot be found in filesystem" if !which($val);
   }
);

has 'flags' => (
   isa => 'HashRef[MyTester::ExecFlag]',
   traits => [qw(Hash)],
   is => 'ro',
   default => sub { {} },
   handles => {
      addFlag => 'set',
      getFlag => 'get',
      getAllFlags => 'values',
      flagCount => 'count',
      hasFlags => 'count'
   }
);

has 'args' => (
   isa => 'ArrayRef[Str]',
   traits => [qw(Array)],
   is => 'rw',
   default => sub { [] },
   handles => {
      addArg => 'push',
      addArgs => 'push',
      getArgs => 'elements',
      hasArgs => 'count'
   }
);

has 'in' => (
   isa => 'Ref',
   is => 'rw',
   default => sub { my $x = undef; return \$x; }
);

has 'out' => (
   isa => 'ScalarRef[Str]',
   is => 'rw',
   default => sub { my $x = ""; return \$x; }
);

has 'err' => (
   isa => 'ScalarRef[Str]',
   is => 'rw',
   default => sub { my $x = ""; return \$x; }
);

################################################################################
# Methods
################################################################################

method derefOut () {
   return ${$self->out()};
}

method derefErr () {
   return ${$self->err()};
}

around addFlag => sub {
   my ($orig, $self, @flags) = @_;
   
   my %flagMap = map { $_->name() => $_ } @flags;
   
   $self->$orig(%flagMap);
   return $self;
};

around getFlag => sub {
   my ($orig, $self, @flags) = @_;
   
   my @flagNames = map {
      my $r = $_;
      if (ref($_) && $_->isa("MyTester::ExecFlag")) { 
         $r = $_->name()
      }
      $r;
   } @flags;
   
   return $self->$orig(@flagNames);
};

method buildHarness (Int :$t? = 0) {
   my @flags = ();
   if ($self->hasFlags()) {
      @flags = map {
         $_->build();
      } $self->getAllFlags();
   }

   my @cmd = ($self->cmd(), @flags, $self->getArgs());
   my @harnessArgs = (
      \@cmd,
      $self->in(),
      $self->out(),
      $self->err());
   
   if ($t > 0) {
      my $timer = timeout($t);
      push(@harnessArgs, $timer);
   }
   
   return harness(@harnessArgs);
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################


1;