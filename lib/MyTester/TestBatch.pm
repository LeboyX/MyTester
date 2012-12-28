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

=head1 Roles Consumed

=for comment
Note that the actual code for this is located at the bottom of the class. See
L<MooseX::Method::Signatures/"BUGS, CAVEATS AND NOTES"> for why the reasons why.

=head2 L<MyTester::Roles::Identifiable>

=head2 L<MyTester::Roles::GenReport>

Extends L<MyTester::Roles::GenReport/reportWithHeader> and 
L<MyTester::Roles::GenReport/reportWithFooter> by setting their defaults 
to true

=head2 L<MyTester::Roles::TrackScores>

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

use MyTester::Reports::Report;
use MyTester::Reports::ReportLine qw(generateDummyReportLine);
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
   isa => 'PositiveInt',
   is => 'rw',
   predicate => '_userSetTestsToRunAtOnce',
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
         filterTests => 'grep',
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
      filterTests => 'grep',
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
       $self->_handleTestFinished($test);
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
      $_->DOES("MyTester::Roles::Dependant")
   } $self->getTests(); 
   for my $dep (@dependants) {
      $dep->evalProviders();
   }
};

method _handleTestFinished(MyTester::Roles::Testable $t) {
   my $id = $t->id();
   
   %{$self->getTest($id)} = %{$t}; #TODO: Fix this!
   
   if ($t->DOES("MyTester::Roles::CanGrade")) {
      my $status = $t->testStatus();
      if ($t->hasGrade($status)) {
         $self->addScore($id, $t->getGradeVal($t->testStatus()));
      }
   }
}

=pod

=head2 buildReport

Does what it sounds like - generates a report of all the tests w/in this batch
based on their C<testStatus>.

B<Returns:> a report of all the tests w/in this batch based on their 
C<testStatus>. More specifically, messages and values are retrieved through
functionality defined in L<MyTester::Roles::CanGrade>.

=cut

method buildReport (PositiveInt :$indent!) {
   my $report = MyTester::Reports::Report->new(
      columns => $self->reportColumns());
   
   for my $test ($self->getTests()) {
      my $testReportLine = ($test->DOES("MyTester::Roles::CanGrade"))
         ? $test->genReport($test->testStatus())
         : $self->_generateDummyReportLine($self->reportColumns());
         
      $testReportLine->indent($indent);
      if ($self->wrapLineRegexDefined()) {
         $testReportLine->computeBrokenLineIndentation(
            $self->reportWrapLineRegex());
      }
      
      $report->addLines($testReportLine);
   }
   
   return $report;
}

=pod

=head3 Decorations

L</buildReport> will croak before running if this batch has not yet been
cooked via L</cookBatch>. 

=cut

before 'buildReport' => sub {
   my $self = shift;
   
   croak "Cannot generate report for uncooked batch" if !$self->cooked();
};

=pod

=head2 buildReportFooter

B<Parameters>

=over

=item $indent! (L<MyTester::Subtypes/PositiveInt>): Indentation level to put 
footer at. While this is required, L<MyTester::Roles::GenReport> silently wraps
this method to always guarantee this gets passed in, even if you don't pass it
yourself.

=back

B<Returns:> L<footer|MyTester::Reports::ReportLine>

=cut

method buildReportFooter (PositiveInt :$indent?) {
   my $line = "Report Summary for '".$self->id()."': ".$self->earned();
   if ($self->maxValid()) {
      $line .= "/".$self->max();
   }
   $line .= " points";
   
   return MyTester::Reports::ReportLine->new(
      indent => $indent,
      line => $line);
}

method _generateDummyReportLine (PositiveInt $columns) {
   my %args = (
      columns => $columns,
   );
   
   $args{line} = 
      "REPORT UNAVAILABLE: Perhaps this represented some intermediary test ".
      "or acted as a stepping stone to setup another test's environment.";
   
   my $reportLine = MyTester::Reports::ReportLine->new(%args);
   
   return $reportLine;
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

with qw(
   MyTester::Roles::GenReport 
   MyTester::Roles::Identifiable
   MyTester::Roles::TrackScores
);

has '+reportWithHeader' => (
   default => 1,
);
has '+reportWithFooter' => (
   default => 1,
);

1;