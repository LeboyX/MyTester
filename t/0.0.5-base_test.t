#!perl
use Modern::Perl '2012';

use Test::More;

use Data::Dumper;
use TryCatch;

use MyTester::ExecEx;
use MyTester::Grade;
use MyTester::TestStatus;
use MyTester::Tests::Base;

################################################################################

my %tests = (
   testDefaultStatus => sub {
      is_deeply(
         MyTester::Tests::Base->new()->testStatus(),
         $MyTester::TestStatus::UNSTARTED,
         "Had 'unstarted' status");
   },

   testTest => sub {
      my $t = MyTester::Tests::Base->new()->test(); 
      is_deeply(
         $t->testStatus(),
         $MyTester::TestStatus::PASSED,
         "Had 'passed' status");
   },
   
   testAfterTest => sub {
      my $t = MyTester::Tests::Base->new()->test()->afterTest();
      is_deeply(
         $t->testStatus(),
         $MyTester::TestStatus::PASSED,
         "Had 'passed' status");
   },
   
   testGrade => sub {
      my $t = MyTester::Tests::Base->new();
      
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
      my $t = MyTester::Tests::Base->new();
      
      my $maxStatus = MyTester::TestStatus->new(key => "max");
      my $maxGrade  = MyTester::Grade->new(val => 100, msg => "Better");
      
      my $g = MyTester::Grade->new(val => 70, msg => "Passed");
      
      $t->setGrade($maxStatus, $maxGrade); 
      $t->setGrade($MyTester::TestStatus::PASSED, $g);
      
      is($t->getResolvedGrade(), undef, "No grade for unmapped status");
      $t->test();
      
      is_deeply($t->getResolvedGrade(), $g, 
         "Got correctly resolved grade after running test");
      
      like($t->getResolvedReport()->line(), qr/70/, 
         "Report has score received");
      like($t->getResolvedReport()->line(), qr/Passed/, 
         "Report has msg received");
      
      like($t->getResolvedReport($maxStatus)->line(), qr/70\/100/,
         "Report has 'X out of Y' w/ max passed in");
      
      $t->maxStatus($maxStatus);
      like($t->getResolvedReport()->line(), qr/70\/100/, 
         "Report has 'X out of Y' w/ max set in attribute");
      
      my $maxToPass = $MyTester::TestStatus::PASSED;
      like($t->getResolvedReport($maxToPass)->line(), qr/70\/70/,
         "Report has 'X out of Y' w/ max passed in to override attribute");
   },
   
   testOnTheFlyExtension => sub {
      package OnTheFlyExtension {
         use Modern::Perl '2012';
         use Moose;
      
         extends 'MyTester::Tests::Base';
         
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