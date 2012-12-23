#!perl

=pod

=head1 Name

MyTester::TestOven - Cooks multiples L<MyTester::TestBatch> objects in 
sequential order, letting you make tests in one batch dependant on the tests in
another, previous batch.

=head1 Version

No set version right now

=head1 Synopsis

TODO

=head1 Description

A TestOven is basically a wrapper to store a list of L<MyTester::TestBatch> 
objects. It provides methods to managed where tests are and to add tests 
before/with/after the batches which contain other tests. 

Unlike a L<MyTester::TestBatch>, a TestOven will run its batches one at a time.
Otherwise, it'd be impossible (or much harder) to maintain dependencies between
tests.

A TestOven cannot contain two identical tests (where their id's are the same).

=cut

package MyTester::TestOven;
use Modern::Perl '2012';
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use Data::Dumper;
use TryCatch;

use MyTester::Subtypes;
use MyTester::TestBatch;
use MyTester::Roles::Dependant;
use MyTester::Roles::Identifiable;
use MyTester::Roles::Provider;
use MyTester::Roles::Testable;

################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 curBatch

   has 'curBatch' => (
      isa => 'MyTester::TestBatch',
      is => 'ro',
      handles => {
         addTest => 'addTest',
         addTestToCurBatch => 'addTest',
         numTestsInCurBatch => 'numTests',
      },
   );
   
The "latest" batch for this oven. This will be the last batch run. Unless you
specify otherwise, tests are added to this batch.

=cut

has 'curBatch' => (
   isa => 'MyTester::TestBatch',
   is => 'ro',
   handles => {
      addTest => 'addTest',
      addTestToCurBatch => 'addTest',
      numTestsInCurBatch => 'numTests',
   },
   writer => '_curBatch',
);

before [qw(addTestToCurBatch addTest)] => sub {
   my ($self, @ts) = @_;
   
   for my $id (map { $_->id() } @ts) {
      if ($self->hasTest($id)) {
         croak "Cannot add duplicate test w/ id '$id'";
      }
   }
};

after [qw(addTestToCurBatch addTest)] => sub {
   my ($self, @ts) = @_;
   
   for my $t (@ts) {
      $self->_recordTest($t, $self->getTestBatchNum($t));
   }
};

=pod

=head2 batches

   has 'batches' => (
      isa => 'ArrayRef[MyTester::TestBatch]',
      traits => [qw(Array)],
      is => 'ro',
      default => sub { [ MyTester::TestBatch->new() ] },
      handles => {
         getBatches => 'elements',
         batchCount => 'count',
         getBatch => 'get',
         searchBatches => 'grep',
         searchBatchIndeces => 'first_index',
      },
   );

Where we store all our L<MyTester::TestBatch> objects for cooking later. 

Note that you can't create/add batches on your own. Instead, that is done in 
methods like L</newBatch>.

=cut

has 'batches' => (
   isa => 'ArrayRef[MyTester::TestBatch]',
   traits => [qw(Array)],
   is => 'ro',
   default => sub { [ MyTester::TestBatch->new() ] },
   handles => {
      getBatches => 'elements',
      batchCount => 'count',
      getBatch => 'get',
      searchBatches => 'grep',
      searchBatchIndeces => 'first_index',
      _addBatch => 'push',
      _getLatestBatch => ['get' => -1],
      _insertBatch => 'insert'
   },
);

has '_testExistsMap' => (
   isa => 'HashRef[Num]',
   traits => [qw(Hash)],
   is => 'ro',
   default => sub { {} },
   handles => {
      numTests => 'count',
   }
);

method _recordTest (TestId $id does coerce, Num $batchNum) {
   return $self->_testExistsMap()->{$id} = $batchNum;
}

method _unrecordTest (TestId $id does coerce) {
   return delete($self->_testExistsMap()->{$id});
}

=pod

=head2 assumeDependencies

   has 'assumeDependencies' => (
      isa => 'Bool',
      is => 'rw',
      default => 0
   );

If set to true, L</addTestBeforeTest> and L</addTestAfter> will make the
test(s) you add be providers for or dependants on (respectively) the test you 
inserted them relative to.

=cut

has 'assumeDependencies' => (
   isa => 'Bool',
   is => 'rw',
   default => 0
);


################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=cut

method BUILD {
   $self->_updateCurBatch();
};

method _updateCurBatch {
   $self->_curBatch($self->_getLatestBatch());
}

=pod

=head2 newBatch

Inserts a new batch at the end of our list of batches. Updates L</curBatch>
to the newly-added batch.

=cut

method newBatch () {
   $self->_addBatch(MyTester::TestBatch->new());
}

after 'newBatch' => sub {
   my ($self) = shift;
   $self->_updateCurBatch();
};

=pod

=head2 hasTest

Whether a given test is in one of this oven's batches or not.

B<Parameters>

=over

=item $id => L<MyTester::Subtypes/TestId>: Testable object or id to lookup

=back

B<Returns:> Whether a given test is in one of this oven's batches or not. 

=cut

method hasTest (TestId $id does coerce) {
   return exists($self->_testExistsMap()->{$id});
}

=pod

=head2 delTest

Deletes a given test from this oven. If the test does not exist in the first
place, this will be a no-op. 

B<Parameters>

=over

=item $id => L<MyTester::Subtypes/TestId>: Testable object or id to delete

=back

=cut

method delTest (TestId $id does coerce) {
   if ($self->hasTest($id)) {
      $self->getTestBatch($id)->delTest($id);
      $self->_unrecordTest($id);
   }
}

=pod

=head2 getTest

Gets a test from within this oven.

B<Parameters>

=over

=item $id => L<MyTester::Subtypes/TestId>: Testable object or id to get. While
you I<can> pass in a L<MyTester::Roles::Testable> object, you'll be asking for
something you already have. So, in most cases, you'll be passing in the id of 
the test to get back the object attached to it. 

=back

B<Returns:> the test associated w/ the L<MyTester::Subtypes/TestId> passed in. 
If the test does not exists, C<undef> is returned.  

=cut

method getTest (TestId $id! does coerce) {
   my $t = undef;
   if ($self->hasTest($id)) {
      $t = $self->getTestBatch($id)->getTest($id);
   }
   return $t;
}

=pod

=head2 getTestBatch

Gets the L<MyTester::TestBatch> object which contains a given 
L<MyTester::Roles::Testable> object.

B<Parameters>

=over

=item $id => L<MyTester::Subtypes/TestId>: Testable object or id to get.

=back

B<Returns:> the L<MyTester::TestBatch> object which contains a given 
L<MyTester::Roles::Testable> object. If the test does not exist in this oven,
returns C<undef>. 

=cut

method getTestBatch (TestId $id! does coerce) {
   my $batch = undef;
   
   if ($self->hasTest($id)) {
      my $index = $self->getTestBatchNum($id);
      if ($index > -1) {
         $batch = $self->getBatch($index);
      }
   }
   return $batch;
}

=pod

=head2 getTestBatchNum

Gets the index (0-based) of the batch containing a given test.

B<Parameters>

=over

=item $id => L<MyTester::Subtypes/TestId>: Testable object or id to get the 
L<MyTester::TestBatch> for

=back

B<Returns:> the index (0-based) of the batch containing a given test. If no
batch contains the given test, you'll get back -1.

=cut

method getTestBatchNum (TestId $id! does coerce) {
   my $index = ($self->searchBatchIndeces(sub {
      $_->hasTest($id);
   }))[0];

   return $index;
}

=pod

=head2 addTestsToBatch

Given a batche's index, will add a list of L<MyTester::Roles::Testable> objects
to it.

If the index you gave doesn't exist (i.e. $batchNum > $batchCount), will 
C<croak> w/ an error. Note that you can use negative indeces.

B<Parameters>

=over

=item [0]: Batch num to insert tests into (required)

=item [1-*]: Slurpy @array of L<MyTester::Roles::Testable> objects to add

=back

B<Returns:> C<$self> 

=cut

method addTestsToBatch (Int $batchNum!, MyTester::Roles::Testable @tests) {
   my $batch = $self->getBatch($batchNum);
   if (!defined $batch) {
      croak "Couldn't find batch num '$batchNum'. We have '" 
         + $self->batchCount() + "' batches";
   }
   $batch->addTest(@tests);
   
   for my $test (@tests) {
      $self->_recordTest($test, $self->getTestBatchNum($test));
   }
   
   return $self;
}

=pod

=head2 addTestsToTestsBatch

Adds a list of tests to the same batch as that of another, provided test (the
"target"). If the target does not exist in this oven, the tests will be added
to the current batch.

B<Parameters>

=over

=item [0]: L<MyTester::Subtypes/TestId> object whose batch we'll be adding other
tests to

=item [1-*]: Slurpy @array of L<MyTester::Roles::Testable> objects to add

=back

B<Returns:> C<$self>

=cut

method addTestToTestsBatch (
      TestId $target! does coerce, 
      MyTester::Roles::Testable @tests!) {
   $self->addTestsToBatch($self->getTestBatchNum($target), @tests);
   
   return $self;
}

=pod

=head2 addTestBefore

Given an "anchoring" test, will add a list of tests to the batch I<before> the
anchoring test. If the anchor test is in the first batch, a new batch will be
inserted before it and shift all current batches over one.

B<Parameters>

=over

=item [0]: L<MyTester::Roles::Testable> whose batch we'll be adding tests
before. Known as the "anchor" test

=item [1-*]: Slurpy @array of L<MyTester::Roles::Testable> object to add before
the given L<MyTester::Subtypes/TestId>.

=back

B<Returns:> C<$self>

=head3 Decorations

If C<assumeDependencies> is set, this method will make the "anchoring" test
dependant on all tests added. More specifically, if the anchor consumes the
L<MyTester::Roles::Dependant> role, all tests added which consume the 
L<MyTester::Roles::Provider> role will be added as providers to the anchor.

=cut

method addTestBefore (
      MyTester::Roles::Testable $anchor!, 
      MyTester::Roles::Testable @tests) {
   my $anchorBatchNum = $self->getTestBatchNum($anchor);
   my $insertIndex = $anchorBatchNum - 1;
   
   if ($anchorBatchNum == 0) {
      $self->_insertBatch(0, MyTester::TestBatch->new());
      $insertIndex = 0;
   }
   $self->addTestsToBatch($insertIndex, @tests);
   
   return $self;
}

after 'addTestBefore' => sub {
   my ($self, $dependant, @providers) = @_;
   
   if ($self->assumeDependencies()) {
      my @providables = grep { 
         $_->DOES("MyTester::Roles::Provider");
      } @providers;
      if ($dependant->DOES("MyTester::Roles::Dependant")) {
         $dependant->addProviders(@providables);
      }
   }
};

=pod

=head2 addTestAfter

Adds a list of tests after a given, "anchor" test

B<Parameters>

=over

=item [0]: L<MyTester::Roles::Testable> object whose batch all given tests will
be added after. Known as the "anchor" test. 

=item [1-*]: Slurpy @array of L<MyTester::Roles::Testable> to add after
the "anchor" tests batch

=back

B<Returns:> C<$self>

=head3 Decorations

If C<assumeDependencies> is set, this method will make the "anchoring" test
provider for all tests added. More specifically, if the anchor consumes the
L<MyTester::Roles::Provider> role, all tests added which consume the 
L<MyTester::Roles::Dependant> role will be made to depend on the anchor.

=cut

method addTestAfter (
      MyTester::Roles::Testable $anchor!, 
      MyTester::Roles::Testable @tests!) {
   my $anchorBatchNum = $self->getTestBatchNum($anchor);
   my $insertIndex = $anchorBatchNum + 1;
   
   if ($insertIndex == $self->batchCount()) {
      $self->newBatch();
   }
   $self->addTestsToBatch($insertIndex, @tests);
   
   return $self;
}

after 'addTestAfter' => sub {
   my ($self, $provider, @dependants) = @_;
   
   if ($self->assumeDependencies()) {
      if ($provider->DOES("MyTester::Roles::Provider")) {
         
         my @deps = grep { 
            $_->DOES("MyTester::Roles::Dependant") 
         } @dependants;
         for my $dep (@deps) {
            $dep->addProviders($provider);
         }
      }
   }
};

=pod

=head2 moveTest

Moves a test from one batch to any batch this oven currently has (including the
one it started in).  

B<Parameters>

=over

=item [0]: L<MyTester::Subtypes/TestId> object representing the test to move

=item [1]: Int (can be a valid, negative index) of what batch you want to move
the test to. If this isn't a valid index (outside the bounds of the current
number of batches), will croak w/ error. 

=back

B<Returns:> C<$self>

=cut

method moveTest (TestId $id! does coerce, Int $batchNum!) {
   my $batchCount = $self->batchCount();
   if ($batchNum > $batchCount) {
      croak "Batch num '$batchNum' > number of batches '$batchCount'"; 
   }
   
   my $test = $self->getTest($id);
   $self->delTest($id);
   $self->addTestsToBatch($batchNum, $test);
   
   return $self;
}

=pod

=head2 cookBatches

Kicks off testing. Will run (cook) each batch in this oven one at a time. 

=cut

method cookBatches () {
   for my $batch ($self->getBatches()) {
      $batch->cookBatch();
   }
}

method generateReport (
      Bool :$generateHeader? = 1,
      PositiveInt :$indent? = 0,
      PositiveInt :$columns? = 80,
      RegexpRef :$delimiter?) {
   if ($generateHeader) {
      
   }
}

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