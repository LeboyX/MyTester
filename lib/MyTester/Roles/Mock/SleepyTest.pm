#!perl
package MyTester::Roles::Mock::SleepyTest;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use Data::Dumper;
use TryCatch;

use MyTester::TestStatus;
################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

has 'interval' => (
   isa => 'Str',
   is => 'rw',
   default => "2",
);

method beforeTest () { }
method canPerformTest () { 1; }

method test () {
   sleep $self->interval();
}

method afterTest() {
   if (!$self->failed()) {
      $self->testStatus($MyTester::TestStatus::PASSED);
   }
}
   
################################################################################
# Methods
################################################################################

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

with qw(MyTester::Roles::Testable);

1;