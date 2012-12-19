#!/usr/bin/perl

=pod

=head1 Name

MyTester::TestStatus - A test's before/during/after execution.

=head1 Version

No set version right now

=head1 Synopsis

   my $customStatus = MyTester::TestStatus->new(
      key => 'alright',
      msg => 'They did alright');
   
   $test->testStatus($customStatus)

=head1 Description

Used after test execution to indicate how the test went. See 
L<MyTester::Grade> and L<MyTester::Roles::CanGrade> for examples of how this
object can be used to map the status of a test to a score and explanatory
message.

=cut

package MyTester::TestStatus;
use Modern::Perl '2012';
use Moose;

=pod

=head1 Public Attributes

=head2 key

   has key => (
      isa => 'Str',
      is => 'rw'
   );

Key for the status. Should never be shared among test statuses. 

=cut

has key => (
   isa => 'Str',
   is => 'rw'
);

=pod

=head2 msg

   has msg => (
      isa => 'Str',
      is => 'rw'
   );

Msg for the status. This should be mostly for debugging and development 
purposes. It isn't mean to be displayed to people receiving grades. 

=cut

has msg => (
   isa => 'Str',
   is => 'rw'
);

=pod

=head1 Constants

=head2 UNSTARTED

   our MyTester::TestStatus $UNSTARTED = MyTester::TestStatus->new(
      key => "unstarted",
      msg => "Test has not yet been started"
   );

Represents an unstarted test. Specifically, "not started" means you haven't
yet called C<test>. 

=cut

our MyTester::TestStatus $UNSTARTED = MyTester::TestStatus->new(
   key => "unstarted",
   msg => "Test has not yet been started"
);

=pod

=head2 PASSED

   our MyTester::TestStatus $PASSED = MyTester::TestStatus->new(
      key => "passed",
      msg => "Test passed"
   );

Means a test has passed unequivocally

=cut

our MyTester::TestStatus $PASSED = MyTester::TestStatus->new(
   key => "passed",
   msg => "Test passed"
);

=pod

=head2 FAILED

   our MyTester::TestStatus $FAILED = MyTester::TestStatus->new(
      key => "failed",
      msg => "Test failed"
   );
   
   Means a test has failed unequivocally. 
   
=cut
   
our MyTester::TestStatus $FAILED = MyTester::TestStatus->new(
   key => "failed",
   msg => "Test failed"
);

=pod

=head2 DEPENDENCY_UNSATISFIED

   our MyTester::TestStatus $DEPENDENCY_UNSATISFIED = MyTester::TestStatus->new(
      key => "dependency_unsatisfied",
      msg => "Dependency unsatisfied"
   );

Represents a test whose providers failed in one form or another. Useful for 
L<MyTester::Roles::Dependant> consumers.

=cut

our MyTester::TestStatus $DEPENDENCY_UNSATISFIED = MyTester::TestStatus->new(
   key => "dependency_unsatisfied",
   msg => "Dependency unsatisfied"
);

1;
