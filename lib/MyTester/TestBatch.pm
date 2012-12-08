#!perl
package MyTester::TestBatch;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use Data::Dumper;

use MyTester::Roles::Testable;

use Parallel::ForkManager;
################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

has 'testsToRunAtOnce' => (
   isa => 'Int',
   is => 'rw',
   trigger => sub {
      my ($self, $val) = @_;
      croak "'testsToRunAtOnce' must be a positive int" if $val < 1;
   }
);

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

has 'cooked' => (
   isa => 'Bool',
   is => 'ro',
   writer => '_cooked',
   default => 0
);

################################################################################
# Methods
################################################################################

method getTestById (Str $id!) {
   return $self->_findTestBy(sub { 
      $_->id() eq $id;
   });
};

method delTestById (Str $id!) {
   my $index = $self->_findTestIndexBy(sub {
      $_->id() eq $id;
   });
   $self->_delTestByIndex($index);
   
   return $self;
}

method delTest (MyTester::Roles::Testable $t!) {
   return $self->delTestById($t->id());
}

method hasTest (MyTester::Roles::Testable :$test?, Str :$id?) {
   my $has;
   if (!$test) {
      if (!defined $id) {
         croak "Must provide a testable object OR an id";
      }
      else {
         $has = $self->getTestById($id);
      }
   }
   else {
      $has = $self->getTestById($test->id());
   }
   
   return $has;
}

method cookBatch () {
   my $fm = Parallel::ForkManager->new($self->testsToRunAtOnce());
   
   $fm->run_on_finish(sub {
      my ($pid, 
          $exit_code, 
          $id, 
          $exit_signal, 
          $core_dump, 
          $test) = @_;
       %{$self->getTestById($id)} = %{$test}; #TODO: Fix this!
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
   if (!defined $self->testsToRunAtOnce) {
      $self->testsToRunAtOnce($self->numTests());
   }
};

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

with qw(MyTester::Roles::Identifiable);

1;