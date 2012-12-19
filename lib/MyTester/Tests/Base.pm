#!perl

=pod

=head1 Name

MyTester::Tests::Base - A simple consumer of L<MyTester::Roles::Testable> and
L<MyTester::Roles::CanGrade>. 

=head1 Version

No set version right now

=head1 Description

This class does nothing on its own, but provides a base for which to extend
your own tests. 

=cut

package MyTester::Tests::Base;
use Modern::Perl '2012';
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

use Data::Dumper;

use Carp;
use TryCatch;

use MyTester::Subtypes;
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

=pod

=head2 getResolvedGrade

Gets the grade associated w/ the current value of C<testStatus>. 

B<Returns:> the grade associated w/ the current value of C<testStatus>. Can be
undef if no mapping was defined for the current status.

=cut

method getResolvedGrade () {
   return $self->getGrade($self->testStatus());
}

=pod

=head2 getResolvedReport

Generated a report representing the L<MyTester::Grade> earned by this tests 
current C<testStatus>.

B<Parameters>

=over

=item [0]? (MyTester::TestStatus): Status representing the max grade. If not 
mapped in the rubric, will throw an error.  

=back

B<Returns:> a report representing the L<MyTester::Grade> earned by this tests 
current C<testStatus>.

B<See:> L<MyTester::CanGrade/genReport>.

=cut

method getResolvedReport (MyTester::TestStatus $max?) {
   return $self->genReport($self->testStatus(), $max);
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