#!perl

=pod

=head1 Name

MyTester::Roles::Mock::EmptyTest - Basic consumer of the 
L<MyTester::Roles::Testable> role

=head1 Version

No set version right now

=head1 Special Notes

=over

=item * The C<afterTest> method will set C<testStatus> to 
$MyTester::TestStatus::PASSED B<only if> C<failed()> does not return true

=back

=cut

package MyTester::Roles::Mock::EmptyTest;
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

method beforeTest () { }

method canPerformTest () { 1; }

method test () { }

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

=pod

=head1 Roles Consumed

=over

=item C<MyTester::Roles::Testable>

=back

=cut

with qw(MyTester::Roles::Testable);

1;