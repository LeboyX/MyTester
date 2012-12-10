#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More;

use Data::Dumper;
use TryCatch;

use MyTester::ExecEx;
use MyTester::Grade;
use MyTester::SimpleTest;
use MyTester::TestStatus;

################################################################################

my %tests = (
   testDefaultStatus => sub {
      is_deeply(
         MyTester::SimpleTest->new()->testStatus(),
         $MyTester::TestStatus::UNSTARTED,
         "Had 'unstarted' status");
   },

   testTest => sub {
      my $t = MyTester::SimpleTest->new()->test(); 
      is_deeply(
         $t->testStatus(),
         $MyTester::TestStatus::PASSED,
         "Had 'passed' status");
   },
   
   testAfterTest => sub {
      my $t = MyTester::SimpleTest->new()->test()->afterTest();
      is_deeply(
         $t->testStatus(),
         $MyTester::TestStatus::PASSED,
         "Had 'passed' status");
   },
   
   testGrade => sub {
      my $t = MyTester::SimpleTest->new();
      
      my $grade = MyTester::Grade->new(
         val => 100,
         msg => "Passed test");

      $t->setGrade($MyTester::TestStatus::PASSED => $grade);
      
      my $actualGrade = $t->getGrade($MyTester::TestStatus::PASSED);
      is_deeply($actualGrade, $grade, "Grade successfully set");
      is_deeply($actualGrade->msg(), $grade->msg(), "Msg's are right");
      is_deeply($actualGrade->val(), $grade->val(), "Val's are right");
   },
   
   testGradeResolution => sub {
      my $t = MyTester::SimpleTest->new();
      my $g = MyTester::Grade->new(val => 100, msg => "Passed");
      
      $t->setGrade($MyTester::TestStatus::PASSED, $g);
      
      is($t->getResolvedGrade(), undef, "No grade for unmapped status");
      $t->test();
      
      is_deeply($t->getResolvedGrade(), $g, 
         "Got correctly resolved grade after running test");
      
   },
   
   testOnTheFlyExtension => sub {
      package OnTheFlyExtension {
         use 5.010;
         use Moose;
      
         extends 'MyTester::SimpleTest';
         
         has 'exec' => (
            isa => 'MyTester::ExecEx',
            is => 'rw',
            default => sub {
               MyTester::ExecEx->new(
                  cmd => "cat"
               );
            },
            handles => {
               buildHarness => 'buildHarness',
               in => 'in',
               out => 'derefOut'
            }
         );
      };
      
      my $x = OnTheFlyExtension->new();
      
      my $inText = qq|
         the quick brown fox jumped over the fence
         but his feet smacked down on a land mine
         and now the quick brown fox is no more
      |;
      my $in = $inText; # Copied b/c harness will empty input var
      $x->in(\$in);
      
      my $h = $x->buildHarness(t => 5);
      $h->pump();
      $h->finish();
      
      is_deeply($x->out(), $inText, "Ran thru harness and got output"); 
   }
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();