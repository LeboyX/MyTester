#!perl

=pod

=head1 Name

MyTester::SimpleTest - A simple consumer of L<MyTester::Roles::Testable> and
L<MyTester::Roles::CanGrade>. 

=head1 Version

No set version right now

=head1 Description

This class does nothing on its own, but provides a base for which to extend
your own tests. 

=cut

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

################################################################################
# Attributes
################################################################################

################################################################################
# Constants
################################################################################

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 beforeTest

Does nothing. Meant to be overridden by children.

B<Returns:> $self

=cut

method beforeTest () {
   return $self;
}

=pod

=head2 canPerformTest

Meant to be overridden by children.

B<Returns:> 1

=cut

method canPerformTest () {
   return 1;
}


=pod

=head2 test

Calls child implementations of the method.

B<Returns:> Either whatever child classes return or, if they return void or 
don't exist, C<$self>.

=cut

method test () {
   return inner() // $self;
}

=pod

=head2 afterTest

Sets C<testStatus> to C<$MyTester::TestStatus::Passed>. Meant to be overridden 
by children.

B<Returns:> C<$self>.

=cut

method afterTest () {
   $self->testStatus($MyTester::TestStatus::PASSED);
   return $self;
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

=pod

=head1 Roles Consumed

=over

=item * MyTester::Roles::Testable

=item * MyTester::Roles::CanGrade

=back

=cut

with qw(MyTester::Roles::Testable MyTester::Roles::CanGrade);

1;