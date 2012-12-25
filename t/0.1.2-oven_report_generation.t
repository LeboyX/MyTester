#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;

use Test::Exception;
use Test::More;

use TryCatch;

use MyTester::Grade;
use MyTester::TestBatch;
use MyTester::TestOven;
use MyTester::TestStatus;
use MyTester::Tests::Base;
################################################################################

sub genOven {
   my ($numBatches, $numTests, $testVal, $testMsg) = @_;
   
   my $oven = MyTester::TestOven->new();
   for (my $i = 0; $i < $numBatches; $i ++) {
      for (my $j = 0; $j < $numTests; $j ++) {
         my $test = MyTester::Tests::Base->new();
         $test->setGrade($MyTester::TestStatus::PASSED,
            MyTester::Grade->new(val => $testVal, msg => $testMsg));
         
         $oven->addTest($test);
      }
      $oven->newBatch();
   }
   return $oven;
}

my %tests = (
   diesIfNotCooked_test => sub {
      my $oven = MyTester::TestOven->new();
      
      dies_ok(sub { $oven->generateReport(); }, 
         "Dies when generating report for uncooked oven");
   },
   
   simpleWholeReport_test => sub {
      my $val = 10;
      my $msg = "Passed the test";
      my $oven = genOven(3, 3, $val, $msg);
      
      $oven->cookBatches();
      
      my $report = $oven->buildReport();
      my $render = $report->render();
      
      my $renderRegex = qr/
         .*\n
         \ {3}.*\n
            (\ {6}\($val\):\ Passed\ the\ test\n){3}
         \ {3}.*\n
            (\ {6}\($val\):\ Passed\ the\ test\n){3}
         \ {3}.*\n
            (\ {6}\($val\):\ Passed\ the\ test\n){2}
            \ {6}\($val\):\ Passed\ the\ test$
      /x;
      like($render, $renderRegex, "Report w/ no header build correctly");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();