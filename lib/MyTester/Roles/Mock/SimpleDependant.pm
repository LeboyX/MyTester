#!perl

=pod

=head1 Name

MyTester::Roles::Mock::SimpleDependant - Basic consumer of the 
L<MyTester::Roles::Dependant> and L<MyTester::Roles::Testable> roles

=head1 Extends

MyTester::Roles::Mock::EmptyTest - for convenience, as this class consumes the 
L<MyTester::Roles::Testable> role.

=head1 Version

No set version right now

=head1 Special Notes

=over

=item * If any of this classes dependents fail their dependency check through 
C<MyTester::Roles::Provider> method C<provides>, this class will call 
L<MyTester::Roles::Testable/testStatus> w/ 
L<MyTester::TestStatus/DEPENDENCY_UNSATISFIED>

=back

=cut

package MyTester::Roles::Mock::SimpleDependant;
use Modern::Perl '2012';
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

extends qw(MyTester::Roles::Mock::EmptyTest);
################################################################################
# Imports
################################################################################
use Carp;
use Data::Dumper;
use TryCatch;

use MyTester::TestStatus;
use MyTester::Roles::Provider;
################################################################################
# Constants
################################################################################

################################################################################
# Attributes
################################################################################

################################################################################
# Methods
################################################################################

=pod

=head1 Consumed Public Methods

=head2 handleFailedProviders

Just calls C<$self-E<gt>fail($MyTester::TestStatus::DEPENDENCY_UNSATISFIED)>, as
the very fact that this method was called means that some dependencies failed.

=head3 Parameters

=over

=item * Slurpy @array of L<MyTester::Roles::Provider> objects

=back

=cut

method handleFailedProviders (MyTester::Roles::Provider @failedProviders) {
   $self->fail($MyTester::TestStatus::DEPENDENCY_UNSATISFIED);
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

=pod

=head1 Roles Consumed

=over

=item * L<MyTester::Roles::Dependant>

=item * L<MyTester::Roles::Testable>

=back

=cut

with qw(MyTester::Roles::Testable MyTester::Roles::Dependant);

1;