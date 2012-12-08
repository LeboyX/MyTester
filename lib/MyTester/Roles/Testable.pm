#!perl

=pod

=head1 Name

MyTester::Roles::Testable - A L<Moose::Role> suitable for consuming in order to 
leverage the rest of the MyTester::* classes. 

=head1 Version

No set version right now

=head1 Synopsis

   package MyTester;
   
   use Moose;
   use MooseX::Method::Signatures;
   with qw(MyTester::Roles::Testable);
   
   method beforeTest () {
      # Perform any pre-test checks
   }
   
   method canPerformTest () {
      return 1; # Perform any necessary checks to ensure test can run safely
   }
   
   method test () {
      # The actual guts of your test
   }
   
   method afterTest () {
      # Any clean up/evaluation work you need done after your test completes
   }

=head1 Description

Creates the foundation around which all tests in the MyTester::* domain should 
be structured. Follows a basic, X-unit test structure: tests have a 'before'
and 'after' phase, during which you can do whatever you need to 
setup/teardown/evaluate the tests environment

=cut

package MyTester::Roles::Testable;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use MyTester::TestStatus;
################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 testStatus

   has 'testStatus' => (
      isa => 'MyTester::TestStatus',
      is => 'rw',
      default => sub { return $MyTester::TestStatus::UNSTARTED; }
   );

The status of this test at the time of calling.

=cut

has 'testStatus' => (
   isa => 'MyTester::TestStatus',
   is => 'rw',
   default => sub { return $MyTester::TestStatus::UNSTARTED; }
);

=pod

=head2 fail

   has 'fail' => (
      isa => 'MyTester::TestStatus',
      is => 'rw',
      trigger => sub {
         my ($self, $val) = @_;
         $self->testStatus($val);
      },
      predicate => 'failed'
   );

Used to immediately preventatively fail this test, forcing it to not run its
test. It's up to consumers whether methods (such as L</afterTest>) should 
account for this setting.

Calling C<fail> will set C<testStatus> to whatever you set passed to C<fail>.

=head3 Public Delegations

=over

=item failed: Determines whether this test has failed or not

=back

=cut

has 'fail' => (
   isa => 'MyTester::TestStatus',
   is => 'rw',
   trigger => sub {
      my ($self, $val) = @_;
      $self->testStatus($val);
   },
   predicate => 'failed',
   clearer => '_unfail'
);

=pod

=head2 wasRun

   has 'wasRun' => (
      isa => 'Bool',
      traits => [qw(Bool)],
      is => 'ro',
      default => 0,
   );

Used to determine whether this test has been run or not. After calling L</test>,
this will be true.

=cut

has 'wasRun' => (
   isa => 'Bool',
   traits => [qw(Bool)],
   is => 'ro',
   default => 0,
   handles => {
      _setRun => 'set',
      _unRun => 'unset',
   }
);

################################################################################
# Methods
################################################################################

=pod

=head1 Required Methods

Consumers must implement the following methods:

=head2 beforeTest

Called before L</test> using Moose's C<before> modifier 
(see L<Moose::Manual::MethodModifiers>). 

=head3 Returns

Whatever you want. The return is ignored here, but you can use this method
elsewhere if you really want to.

=head2 canPerformTest

Called before L</test> to determine whether we can proceed w/ testing.

=head3 Returns

Whether we can proceed w/ testing. If you set L</fail>, this method will always
return false.

=head2 test

The actual guts of your tests. Do whatever you need to do to run your test 
within this method.

=head3 Returns

Whatever you want. 

=cut

requires qw(beforeTest test afterTest canPerformTest);

around 'canPerformTest' => sub {
   my ($orig, $self, @args) = @_;
   
   return !$self->failed() && $self->$orig(@args);
};

before 'test' => sub { 
   my $self = shift;
   $self->beforeTest();
};

around 'test' => sub {
   my ($orig, $self, @args) = @_;
   
   my $ret;
   if ($self->canPerformTest()) {
      $self->_setRun();
      $ret = $self->$orig(@args);
   }
   
   return $ret;
};

after 'test' => sub {
   my $self = shift;
   $self->afterTest();
};

=pod

=head1 Provided Methods

=head2 restart

Resets the state var's of this object back to their initial, default setting. By
default, this will do the following:

=over

=item * Set C<wasRun> to false

=item * Reset/clear C<fail>

=item * Set C<testStatus> back to $MyTester::TestStatus::UNSTARTED (see
L<MyTester::TestStatus/Public Statuses>)

=back

Child classes can override this method to do additional work to reset their
testing environment.

=cut

method restart {
    $self->_unRun();
    $self->_unfail();
    $self->testStatus($MyTester::TestStatus::UNSTARTED);
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

=pod

=head1 Applied Roles

=over

=item * L<MyTester::Roles::Identifiable>: Useful to make every test you create
easily identifiable. 

=back

=cut

with qw(MyTester::Roles::Identifiable);

1;
