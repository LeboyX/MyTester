#!perl

=pod

=head1 Name

MyTester::Roles::Mock::SleepyTest - Simple consumer of the 
L<MyTester::Roles::Testable> role. You can guess what it does. 

=head1 Version

No set version right now

=head1 Description

Performs a simple "sleep" test; it sleep for a given interval. Useful for 
testing in parallel to make sure that, indeed, things are running in parallel.

=cut

package MyTester::Roles::Mock::SleepyTest;
use Modern::Perl '2012';
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

=pod

=head1 Public Attributes

=head2 interval

   has 'interval' => (
      isa => 'Str',
      is => 'rw',
      default => "2",
   );
   
How long you want this test to sleep for

=cut

has 'interval' => (
   isa => 'Str',
   is => 'rw',
   default => "2",
);

################################################################################
# Methods
################################################################################

=pod

=head1 Consumed Public Methods

=head2 MyTester::Roles::Testable::beforeTest

Does nothing

=cut

method beforeTest () { }

=pod

=head2 MyTester::Roles::Testable::canPerformTest

Returns true

=cut

method canPerformTest () { 1; }

=pod

=head2 MyTester::Roles::Testable::Test

Sleeps for C<$self-E<gt>interval()> seconds

=cut

method test () {
   sleep $self->interval();
}

=pod

=head2 MyTester::Roles::Testable::afterTest

So long as this object wasn't failed (see L<MyTester::Roles::Testable/fail>),
will set C<testStatus> to C<$MyTester::TestStatus::PASSED>.

=cut

method afterTest() {
   if (!$self->failed()) {
      $self->testStatus($MyTester::TestStatus::PASSED);
   }
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

=pod

=head1 Roles Consumed

=over

=item MyTester::Roles::Testable

=back

=cut

with qw(MyTester::Roles::Testable);

1;