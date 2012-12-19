#!perl

=pod

=head1 Name

MyTester::TestBatch - Represents a set of tests to be run concurrently (like 
cooking a batch of cookies in the oven). 

=head1 Version

No set version right now

=head1 Synopsis

   my $tb = MyTester::TestBatch->new();
   
   my @tests = ();
   push(@tests, MyTester::Roles::Mock::SleepyTest->new(
      interval => 2
   )) for 1..3;
   
   $tb->addTest(@tests);
   $tb->delTests($tests[0]);
   
   $tb->cookBatch(); # Will take 2s, b/c we have two 2s tests run in parallel
   
=head1 Description

This of tests as cookies and a L<MyTester::TestBatch> as the cookie sheet they
go on in the oven. Each tests begin at (or nearly at) the same time as all the
other tests. In practice, this won't be perfect b/c of the overhead needed to
fork and manage the various tests. Furthermore, if you don't want to burden
the system, you can limit how many tests are run at a given time.  

See L<Parallel::ForkManager> for details on how we manage our forked tests. 

=cut

package MyTester::TestBatch;
use Modern::Perl '2012';
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use Data::Dumper;

use MyTester::Roles::Testable;
use MyTester::Subtypes;

use Parallel::ForkManager;
################################################################################
# Constants
################################################################################

################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 testsToRunAtOnce

   has 'testsToRunAtOnce' => (
      isa => 'Int',
      is => 'rw',
      trigger => sub {
         my ($self, $val) = @_;
         croak "'testsToRunAtOnce' must be a positive int" if $val < 1;
      }
   );

How many tests to run in parallel at once. If you don't set this, it'll default
at runtime to the number of tests in this batch.

=cut

has 'testsToRunAtOnce' => (
   isa => 'Int',
   is => 'rw',
   predicate => '_userSetTestsToRunAtOnce',
   trigger => sub {
      my ($self, $val) = @_;
      croak "'testsToRunAtOnce' must be a positive int" if $val < 1;
   }
);

=pod

=head2 tests

   has 'tests' => ( 
      isa => 'ArrayRef[MyTester::Roles::Testable]',
      traits => [qw(Array)],
      is => 'ro',
      default => sub { [] },
      handles => {
         addTest => 'push',
         getTests => 'elements',
         numTests => 'count',
         clearTests => 'clear',
      },
      writer => '_tests'
   );

Tests to L</cook> in this batch. 

=cut
   
has 'tests' => ( 
   isa => 'ArrayRef[MyTester::Roles::Testable]',
   traits => [qw(Array)],
   is => 'ro',
   default => sub { [] },
   handles => {
      addTest => 'push',
      getTests => 'elements',
      numTests => 'count',
      clearTests => 'clear',
      _findTestBy => 'first',
      _findTestIndexBy => 'first_index',
      _delTestByIndex => 'delete',
   },
   writer => '_tests'
);

=pod

=head2 cooked

   has 'cooked' => (
      isa => 'Bool',
      is => 'ro',
      default => 0,
   );

Whether this batch has fully cooked (all tests run/completed). Set internally.

=cut

has 'cooked' => (
   isa => 'Bool',
   is => 'ro',
   default => 0,
   writer => '_cooked',
);

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 getTest

Returns the L<MyTester::Roles::Testable> object w/ the given id. Can be undef
if the test doesn't exist in this batch.

B<Parameters>

=over

=item * [0]: L<MyTester::Subtypes/TestId> to lookup test with. 

=back

B<Returns:> the L<MyTester::Roles::Testable> object w/ the given id. Can be 
undef if the test doesn't exist in this batch.

=cut

method getTest (TestId $id! does coerce) {
   return $self->_findTestBy(sub { 
      $_->id() eq $id;
   });
};

=pod

=head2 delTest

Deletes the test. If the test doesn't exist in this batch, this is a no-op. 

B<Parameters>

=over

=item [0]: L<MyTester::Subtypes/TestId> to delete test by.

=back

B<Returns:> C<$self>

=cut

method delTest (TestId $id! does coerce) {
   my $index = $self->_findTestIndexBy(sub {
      $_->id() eq $id;
   });
   $self->_delTestByIndex($index);
   
   return $self;}

=pod

=head2 hasTest

B<Parameters>

=over

=item $test => L<MyTester::Roles::Testable>: Test to find

=item $id => Str: Id of test to find

=back

One of the above parameters must be provided or this will croak. 

B<Returns:> The test itself if it exists. Undefined otherwise 

=cut

method hasTest (TestId $id does coerce) {
   return $self->getTest($id);
}

=pod

=head2 cookBatch

Runs all the tests in this, with as many running at a given time as is set in
L</testsToRunAtOnce>. 

=head3 Decorations

If you haven't yet set L</testsToRunAtOnce> when calling this method, it will
be set to however many tests are currently in this batch.

Also, before tests in a batch are run, C<evalProviders> is called on each 
L<MyTester::Roles::Dependant> consumer in this batch. 

=cut

method cookBatch () {
   my $fm = Parallel::ForkManager->new($self->testsToRunAtOnce());
   
   $fm->run_on_finish(sub {
      my ($pid, 
          $exit_code, 
          $id, 
          $exit_signal, 
          $core_dump, 
          $test) = @_;
       %{$self->getTest($id)} = %{$test}; #TODO: Fix this!
   });
   
   for my $test ($self->getTests()) {
      $fm->start($test->id()) and next;
      $test->test();
      $fm->finish(0, $test);
   }
   
   $fm->wait_all_children();
   
   $self->_cooked(1);
}

before 'cookBatch' => sub {
   my ($self) = @_;
   if (!$self->_userSetTestsToRunAtOnce()) {
      $self->testsToRunAtOnce($self->numTests());
   }
   
   my @dependants = grep { 
      $_->meta()->does_role("MyTester::Roles::Dependant")
   } $self->getTests(); 
   for my $dep (@dependants) {
      $dep->evalProviders();
   }
};

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

=pod

=head1 Roles Consumed

=over

=item MyTester::Roles::Identifiable

=back

=cut

with qw(MyTester::Roles::Identifiable);

1;