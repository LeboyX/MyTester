#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Time::HiRes qw(time);

use Test::More;

use TryCatch;

use MyTester::SleepyTest;
use MyTester::TestStatus;
use MyTester::Roles::Testable;
use MyTester::Roles::Mock::EmptyTest;

################################################################################

my %tests = (
   idDefault_test => sub {
      my $startingId = MyTester::Roles::Mock::EmptyTest->new()->id();
      is(MyTester::Roles::Mock::EmptyTest->new()->id(), 
         $startingId + 1, "0th id correct");
      is(MyTester::Roles::Mock::EmptyTest->new()->id(), 
         $startingId + 2, "1st id correct");
      is(MyTester::Roles::Mock::EmptyTest->new()->id(), 
         $startingId + 3, "2nd id correct");
   },
   
   failImmediately_test => sub {
      my $t = MyTester::Roles::Mock::EmptyTest
         ->new(fail => $MyTester::TestStatus::FAILED);
      
      my $startTime = time;
      $t->test();
      my $endTime = time;
      
      is_deeply($t->fail(), $MyTester::TestStatus::FAILED, "Fail status set");
      is_deeply($t->testStatus(), $MyTester::TestStatus::FAILED,
         "Test status set to fail status");
      cmp_ok($endTime - $startTime, '<', 1, "Test didn't run");
   },
   
   wasRun_test => sub {
      my $t = MyTester::Roles::Mock::EmptyTest->new();
      
      ok(!$t->wasRun(), "Test says it wasn't yet run");
      $t->test();
      ok($t->wasRun(), "Test says it was run");
   },
   
   restartTest_test => sub {
      my $t = MyTester::Roles::Mock::EmptyTest
         ->new(fail => $MyTester::TestStatus::FAILED);
      
      $t->test();
      $t->restart();
      
      ok(!$t->wasRun(), "Restart reset 'wasRun' status");
      ok(!$t->failed(), "Restart reset 'fail' status");
      is_deeply($t->testStatus(), $MyTester::TestStatus::UNSTARTED,
         "Restart reset 'testStatus' status");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();