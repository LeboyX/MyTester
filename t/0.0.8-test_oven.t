#!perl
use Modern::Perl '2012';

use Time::HiRes qw(time);

use Data::Dumper;

use Test::Exception;
use Test::More;

use TryCatch;

use MyTester::ExecEx;
use MyTester::TestOven;
use MyTester::Roles::Provider;
use MyTester::Roles::Testable;
use MyTester::Roles::Mock::EmptyTest;
use MyTester::Roles::Mock::PuppetProvider;
use MyTester::Roles::Mock::SimpleDependant;
use MyTester::Roles::Mock::SleepyTest;


my %tests = (
   constructorTest_test => sub {
      my $oven = MyTester::TestOven->new();
      
      is($oven->batchCount(), 1, "New oven has one batch at construction");
   },
   
   newBatchTest_test => sub {
      my $oven = MyTester::TestOven->new();
      
      my $oldCur = $oven->curBatch();
      $oven->newBatch();
      my $newCur = $oven->curBatch();
      
      isnt($oldCur->id(), $newCur->id(), "New batch has different id");
      is($oven->batchCount(), 2, "Batch count increased");
      is_deeply($oven->getBatch(0), $oldCur, "Old batch is first in batch list");
      is_deeply($oven->getBatch(1), $newCur, "New batch is last in batch list");
   },
   
   addTestsToBatchesTest_test => sub {
      my $oven = MyTester::TestOven->new();
      
      my @b1Tests = (
         MyTester::Roles::Mock::SleepyTest->new(), 
         MyTester::Roles::Mock::SleepyTest->new());
      my @b2Tests = (
         MyTester::Roles::Mock::SleepyTest->new(), 
         MyTester::Roles::Mock::SleepyTest->new());
      
      $oven->addTestToCurBatch(@b1Tests);
      $oven->newBatch();
      $oven->addTestToCurBatch(@b2Tests);
      
      my $b1 = $oven->getBatch(0);
      my $b2 = $oven->getBatch(1);
      is_deeply([$b1->getTests()], [@b1Tests], 
         "Batch 1 tests accessible and existent");
      is_deeply([$b2->getTests()], [@b2Tests], 
         "Batch 2 tests accessible and existent");
      
      is_deeply($oven->getTestBatch($b1Tests[0]), $b1, "Got batch for b1 test");
      is_deeply($oven->getTestBatch($b2Tests[0]), $b2, "Got batch for b2 test");
         
      ok($oven->hasTest($b1Tests[0]), "b1Test1 exists in oven");
      ok($oven->hasTest($b2Tests[1]), "b2Test2 exists in oven");
   },
   
   addDupTestsTest_test => sub {
      my $oven = MyTester::TestOven->new();
      
      my $dupId = "idToDup";
      my $test = MyTester::Roles::Mock::EmptyTest->new(id => $dupId);
      my $dup = MyTester::Roles::Mock::EmptyTest->new(id => $dupId);
      
      $oven->addTestToCurBatch($test);
      dies_ok(sub { $oven->addTestToCurBatch($dup) } , 
         "Threw exception when adding duplicate test");
      is($oven->numTestsInCurBatch(), 1, "Duplicate test not added");
   },
   
   delTestsFromBatchesTest_test => sub {
      my $oven = MyTester::TestOven->new();
      
      my @b1Tests = (
         MyTester::Roles::Mock::SleepyTest->new(id => "1_b1Test"), 
         MyTester::Roles::Mock::SleepyTest->new(id => "2_b1Test"));
         
      $oven->addTestToCurBatch(@b1Tests);
      
      $oven->delTest($b1Tests[0]);
      is($oven->numTestsInCurBatch(), 1, 
         "Test from first batch deleted by obj");
         
      $oven->delTest($b1Tests[1]);
      is($oven->numTestsInCurBatch(), 0, 
         "Test from first batch deleted by id");
         
      $oven->delTest($b1Tests[0]);
      pass("Deleting non-existent test did nothing");
      
      is($oven->getTestBatch($b1Tests[0]), undef, "No batch for b1 test 1");
      is($oven->getTestBatch($b1Tests[1]), undef, "No batch for b1 test 2");
         
      ok(!$oven->hasTest($b1Tests[0]), "b1Test1 doesn't exist in oven");
      ok(!$oven->hasTest($b1Tests[1]), "b1Test2 doesn't exist in oven");
   },
   
   addTestBeforeTest_test => sub {
      my $oven = MyTester::TestOven->new();
      
      my $firstTest = 
         MyTester::Roles::Mock::EmptyTest->new(id => "first");
      my $middleTest = 
         MyTester::Roles::Mock::EmptyTest->new(id => "middle");
      my $extraMiddleTest = 
         MyTester::Roles::Mock::EmptyTest->new(id => "extraMiddle");
      my $lastTest = 
         MyTester::Roles::Mock::EmptyTest->new(id => "last");
      
      $oven->addTestToCurBatch($lastTest);
      $oven->addTestBefore($lastTest, $middleTest, $extraMiddleTest)
         ->addTestBefore($middleTest, $firstTest);
      
      for ($firstTest, $middleTest, $extraMiddleTest, $lastTest) {
         ok($oven->hasTest($_), "Oven says we have '".$_->id()."'");
      }
      
      my %batchNums = (
         'first' => $oven->getTestBatchNum($firstTest),
         'middle' => $oven->getTestBatchNum($middleTest),
         'extraMiddle' => $oven->getTestBatchNum($extraMiddleTest),
         'last' => $oven->getTestBatchNum($lastTest),
      );
      
      while (my ($name, $i) = each(%batchNums)) {
         cmp_ok($i, '>', -1, "'$name' is valid index");
      }
      
      cmp_ok($batchNums{middle}, '<', $batchNums{last}, 
         "Middle test batch < last test batch");
      cmp_ok($batchNums{middle}, '==', $batchNums{extraMiddle},
         "Middle tests in same batch");
      cmp_ok($batchNums{first}, '<', $batchNums{middle}, 
         "First test batch < middle");
         
      is($oven->batchCount(), 3, "3 batches for first, middle, and last tests");
   },
   
   addTestAfterTest_test => sub {
      my $oven = MyTester::TestOven->new();
      
      my $lastTest = 
         MyTester::Roles::Mock::EmptyTest->new(id => "first");
      my $middleTest = 
         MyTester::Roles::Mock::EmptyTest->new(id => "middle");
      my $extraMiddleTest =
         MyTester::Roles::Mock::EmptyTest->new(id => "extraMiddle");
      my $firstTest = 
         MyTester::Roles::Mock::EmptyTest->new(id => "last");
      
      $oven->addTestToCurBatch($firstTest);
      
      $oven->addTestAfter($firstTest, $middleTest, $extraMiddleTest);
      $oven->addTestAfter($middleTest, $lastTest);
      
      for ($firstTest, $middleTest, $extraMiddleTest, $lastTest) {
         ok($oven->hasTest($_), "Oven says we have '".$_->id()."'");
      }
      
      my %batchNums = (
         'first' => $oven->getTestBatchNum($firstTest),
         'middle' => $oven->getTestBatchNum($middleTest),
         'extraMiddle' => $oven->getTestBatchNum($extraMiddleTest),
         'last' => $oven->getTestBatchNum($lastTest),
      );
      
      while (my ($name, $i) = each(%batchNums)) {
         cmp_ok($i, '>', -1, "'$name' is valid index");
      }
      
      cmp_ok($batchNums{middle}, '<', $batchNums{last}, 
         "Middle test batch < last test batch");
      cmp_ok($batchNums{middle}, '==', $batchNums{extraMiddle},
         "Middle tests in same batch");
      cmp_ok($batchNums{first}, '<', $batchNums{middle}, 
         "First test batch < middle");
      
      is($oven->batchCount(), 3, "3 batches for first, middle, and last tests");
   },
   
   addTestToTestsBatchTest_test => sub {
      my $oven = MyTester::TestOven->new();
      
      my $targetTest = MyTester::Roles::Mock::EmptyTest->new(id => "target");
      my $testToPush = MyTester::Roles::Mock::EmptyTest->new(id => "toPush");
      
      $oven->addTestToCurBatch($targetTest);
      $oven->addTestToTestsBatch($targetTest, $testToPush);
      
      my $targetBatchNum = $oven->getTestBatchNum($targetTest);
      is($targetBatchNum, $oven->getTestBatchNum($testToPush),
         "Added test in batch w/ target test");
      
      my $batch = $oven->getTestBatch($targetTest);
      is($batch->numTests(), 2, "Batch's test count reflects both tests");
   },
   
   moveTestTest_test => sub {
      my $oven = MyTester::TestOven->new();
      
      my $test = MyTester::Roles::Mock::EmptyTest->new(id => "moveMe");
      $oven->addTestToCurBatch($test);
      $oven->newBatch();
      $oven->moveTest($test, 1);
      
      is($oven->numTestsInCurBatch(), 1, 
         "Test moved from prior batch to cur batch");
      ok($oven->hasTest($test), "Oven says we have test");
      is($oven->getTestBatchNum($test), 1, 
         "Test batch num reflects move");
   },
   
   testFullCook_test => sub {
      my $oven = MyTester::TestOven->new(id => 'ovenToCook');
      
      $oven
         ->addTestToCurBatch(MyTester::Roles::Mock::SleepyTest->new()) for 1..4;
      $oven->newBatch();
      $oven->addTestToCurBatch(MyTester::Roles::Mock::SleepyTest->new());
      $oven->newBatch();
      $oven->addTestToCurBatch(MyTester::Roles::Mock::SleepyTest->new());
      
      is($oven->numTests, 6, "Six tests added");
      
      my $startTime = time();
      $oven->cookBatches();
      my $endTime = time();
      
      my $interval = $endTime - $startTime;
      ok($interval > 5 && $interval < 7, sprintf(
         "Oven cooked all batches in time: 5 < %.2f < 7", $interval));
         
      for my $batch ($oven->getBatches()) {
         my $batchId = $batch->id();
         for my $test ($batch->getTests()) {
            my $testId = $test->id();
            is_deeply($test->testStatus(), $MyTester::TestStatus::PASSED, 
               "Batch '$batchId' ran test '$testId' to conclusion (PASSED)");
         }
      }
   },
   
   assumeDepsBefore_test => sub {
      my $oven = MyTester::TestOven->new(assumeDependencies => 1);
      
      my $provider = 
         MyTester::Roles::Mock::PuppetProvider->new(id => "poorProvider");
      my $nonProvider = 
         MyTester::Roles::Mock::EmptyTest->new(id => "non-dependable");
      my $dependant = 
         MyTester::Roles::Mock::SimpleDependant->new(id => "doNotRun");
      
      $oven->addTest($dependant);
      $oven->addTestBefore($dependant, $provider, $nonProvider);
      
      is($dependant->providerCount(), 1, "1 dependency added");
      
      $oven->cookBatches();
      for ($oven->getBatch(0)->getTests()) {
         my $id = $_->id();
         ok($_->wasRun(), "Provider '$id' was run");
         is_deeply($_->testStatus(), $MyTester::TestStatus::PASSED,
            "Provider '$id' has 'PASSED' status");
      }
      
      is_deeply(
         $dependant->testStatus(), 
         $MyTester::TestStatus::DEPENDENCY_UNSATISFIED,
         "Dependant had status for unsatisfied dependency after cooking");
      ok(!$dependant->wasRun(), "Dependent wasn't run");
      isnt($dependant->providersFailed(), 0, "Dependant sees failed providers");
   },
   
   assumeDepsAfter_test => sub {
      my $oven = MyTester::TestOven->new(assumeDependencies => 1);
      
      my $provider = MyTester::Roles::Mock::PuppetProvider->new();
      my $dependant = 
         MyTester::Roles::Mock::SimpleDependant->new(id => "doNotRun");

      $oven->addTest($provider);
      $oven->addTestAfter($provider, $dependant);
      
      is($dependant->providerCount(), 1, "1 dependency added");
      
      $oven->cookBatches();
      
      for ($oven->getBatch(0)->getTests()) {
         my $id = $_->id();
         ok($_->wasRun(), "Provider '$id' was run");
         is_deeply($_->testStatus(), $MyTester::TestStatus::PASSED,
            "Provider '$id' has 'PASSED' status");
      }
      
      is_deeply(
         $dependant->testStatus(), 
         $MyTester::TestStatus::DEPENDENCY_UNSATISFIED,
         "Dependant had status for unsatisfied dependency after cooking");
      ok(!$dependant->wasRun(), "Dependant wasn't run");
      ok($dependant->providersFailed(), "Dependant records failed providers");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();