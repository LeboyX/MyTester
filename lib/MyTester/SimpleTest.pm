#!perl
package MyTester::SimpleTest;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

use Data::Dumper;

use Carp;
use TryCatch;

use MyTester::TestStatus;

################################################################################
# Imports
################################################################################

use MyTester::Grade;

################################################################################
# Attributes
################################################################################

has 'rubric' => (
   isa => 'HashRef[MyTester::Grade]',
   traits => [qw(Hash)],
   is => 'ro',
   default => sub { {} },
   handles => {
      setGrade => 'set',
      getGrade => 'get'
   }
);

################################################################################
# Constants
################################################################################

################################################################################
# Methods
################################################################################

method beforeTest () {
   return $self;
}

method canPerformTest () {
   return 1;
}

method test () {
   $self->testStatus($MyTester::TestStatus::PENDING_EVAL);
   return $self;
}

method afterTest () {
   $self->testStatus($MyTester::TestStatus::PASSED);
   return $self;
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

with qw(MyTester::Roles::Testable MyTester::Roles::CanGrade);

1;