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
objects. It  provided methods to managed where tests are and to add tests 
before/with/after the batches which contain other tests. 

Unlike a L<MyTester::TestBatch>, a TestOven will run its batches one at a time.
Otherwise, it'd be impossible (or much harder) to maintain dependencies between
tests.

A TestOven cannot contain two identical tests (there id's are the same).

=cut

package MyTester::TestOven;
use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
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

before 'addTestToCurBatch' => sub {
   my ($self, @ts) = @_;
   
   for my $id (map { $_->id() } @ts) {
      if ($self->hasTest($id)) {
         croak "Cannot add duplicate test w/ id '$id'";
      }
   }
};

after 'addTestToCurBatch' => sub {
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

Note that you can't create add batches on your own. Instead, that is done in 
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

method hasTest (TestId $id does coerce) {
   return exists($self->_testExistsMap()->{$id});
}

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

If set to true, L</addTestBeforeTest> and L</addTestAfterTest> will make the
test(s) you add be providers for or dependants on (respectively) the test you 
inserted them relative to

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

method delTest (TestId $id does coerce) {
   $self->getTestBatch($id)->delTest($id);
}

after 'delTest' => sub {
   my ($self, $id) = @_;
   $self->_unrecordTest($id);
};

method getTest (TestId $id! does coerce) {
   return $self->getTestBatch($id)->getTest($id);
}

method getTestBatch (TestId $id! does coerce) {
   my $index = $self->getTestBatchNum($id);
   if (defined $index && $index > -1) {
      return $self->getBatch($index);
   }
   else {
      return undef;
   }
}

method getTestBatchNum (TestId $id! does coerce) {
   my $index = ($self->searchBatchIndeces(sub {
      $_->hasTest($id);
   }))[0];

   if ($index == -1) {
      croak "Oven does not currently have test w/ id '$id'";
   }
   
   return $index;
}

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

method addTestToTestsBatch (
      MyTester::Roles::Testable $target!, 
      MyTester::Roles::Testable @tests!) {
   $self->addTestsToBatch($self->getTestBatchNum($target), @tests);
   
   return $self;
}

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
         $_->meta()->does_role("MyTester::Roles::Provider");
      } @providers;
      if ($dependant->meta()->does_role("MyTester::Roles::Dependant")) {
         $dependant->addProviders(@providables);
      }
   }
};

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
      if ($provider->meta()->does_role("MyTester::Roles::Provider")) {
         
         my @deps = grep { 
            $_->meta()->does_role("MyTester::Roles::Dependant") 
         } @dependants;
         for my $dep (@deps) {
            $dep->addProviders($provider);
         }
      }
   }
};

method getTestDepCount (MyTester::Roles::Dependant $dep) {
   return $dep->providerCount();
}

method moveTest (TestId $id! does coerce, Int $batchNum!) {
   my $batchCount = $self->batchCount();
   if ($batchNum > $batchCount) {
      croak "Batch num '$batchNum' > number of batches '$batchCount'"; 
   }
   
   my $test = $self->getTest($id);
   $self->delTest($test);
   $self->addTestsToBatch($batchNum, $test);
   
   return $self;
}

method cookBatches () {
   for my $batch ($self->getBatches()) {
      my @dependants = grep { 
         $_->meta()->does_role("MyTester::Roles::Dependant")
      } $batch->getTests(); 
      for my $dep (@dependants) {
         $dep->evalProviders();
      }
      
      $batch->cookBatch();
   }
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

with qw(MyTester::Roles::Identifiable);

1;