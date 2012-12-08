#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Time::HiRes qw(time);
use TryCatch;

use Math::Round qw(nearest_ceil);

use MyTester::ExecEx;
use MyTester::TestBatch;
use MyTester::Roles::Testable; 
use MyTester::Roles::Mock::EmptyTest;
use MyTester::Roles::Mock::SleepyTest;
################################################################################

my %tests = (
   pushAndRetrieveTest => sub {
      my $tb = MyTester::TestBatch->new();
      
      my @ts = ();
      push(@ts, MyTester::Roles::Mock::EmptyTest->new()) for 1..3; 
      my $numTests = scalar @ts;
      
      $tb->addTest(@ts);
      
      is($tb->numTests(), $numTests, "Added '$numTests' tests");
      
      my @retrievedTests = $tb->getTests();
      is_deeply($retrievedTests[0], $ts[0], "1st test at expected index");
      is_deeply($retrievedTests[1], $ts[1], "2nd test at expected index");
      is_deeply($retrievedTests[2], $ts[2], "3rd test at expected index");
      
      is_deeply($tb->getTestById($ts[0]->id), $ts[0], "Found 1st test by id");
      is_deeply($tb->getTestById($ts[1]->id), $ts[1], "Found 2nd test by id");
      is_deeply($tb->getTestById($ts[2]->id), $ts[2], "Found 3rd test by id");
   },
   
   pushAndDelTest => sub {
      my $tb = MyTester::TestBatch->new();
      
      my @ts = ();
      push (@ts, MyTester::Roles::Mock::EmptyTest->new()) for 1..3;
      
      $tb->addTest(@ts);
      
      $tb->delTestById($ts[0]->id());
      is(scalar $tb->getTests(), 2, "Test list one less");
      is($tb->getTestById($ts[0]->id()), undef, 
         "1st test couldn't be found by id");
      
      $tb->delTest($ts[1]);
      is(scalar $tb->getTests(), 1, "Test list two less");
      is($tb->getTestById($ts[1]->id()), undef, 
         "2nd test couldn't be found by id");
   },
   
   runInParallelTest => sub {
      my $numTests = 3;
      my $testsToRunAtOnce = 2;
      
      my $tb = MyTester::TestBatch->new(testsToRunAtOnce => $testsToRunAtOnce);
      
      $tb->addTest(MyTester::Roles::Mock::SleepyTest->new()) for 1..$numTests;
      
      my $startTime = time();
      $tb->cookBatch();
      my $endTime = time();
      
      my $cookingRuns = int(($numTests / $testsToRunAtOnce));
      if ($numTests % $testsToRunAtOnce != 0) {
         $cookingRuns ++;
      }
      my $targetTime = $cookingRuns * 2;
      my $elapsedTime = $endTime - $startTime;
      my $lowerBound = $targetTime - 1;
      my $upperBound = $targetTime + 1;
      ok(($elapsedTime > $lowerBound) && ($elapsedTime < $upperBound), 
         sprintf("Time: ${lowerBound}s < %.2fs < ${upperBound}", $elapsedTime));
   },
   
   examineTestsAfterCooking => sub {
      my $tb = MyTester::TestBatch->new(testsToRunAtOnce => 2);
      
      $tb->addTest(MyTester::Roles::Mock::SleepyTest->new()) for 1..2;
      
      for ($tb->getTests()) {
         is_deeply($_->testStatus(), $MyTester::TestStatus::UNSTARTED,
            "Tests unstarted before cooking");
      }
      
      ok(!$tb->cooked(), "Batch isn't cooked yet");
      $tb->cookBatch();
      ok($tb->cooked(), "Batch was cooked");
      
      for ($tb->getTests()) {
         my $id = $_->id();
         is_deeply($_->testStatus(), $MyTester::TestStatus::PASSED,
            "Test '$id' passed after cooking");
         ok($_->wasRun, "Test '$id' says 'wasRun'"); 
      }
   }
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();