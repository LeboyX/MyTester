#!perl
package MyTester::ExecFlag;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

################################################################################
# Attributes
################################################################################

has 'name' => (
   isa => 'Str',
   required => 1,
   is => 'rw'
);

has 'args' => (
   isa => 'ArrayRef[Str]',
   traits => [qw(Array)],
   is => 'ro',
   default => sub { [] },
   handles => {
      addArg => 'push',
      getArgs => 'elements',
   }
);

has 'isLong' => (
   isa => 'Bool',
   is => 'rw',
   default => 0
);

################################################################################
# Methods
################################################################################

method build () {
   my $flag = "-";
   if ($self->isLong()) {
      $flag .= "-";
   }
   $flag .= $self->name();
   
   return ($flag, join(" ", $self->getArgs()));;
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

1;