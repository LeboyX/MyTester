#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use Data::Dumper;
use TryCatch;

use MyTester::Grade;
use MyTester::TestBatch;
use MyTester::TestStatus;
use MyTester::Roles::Mock::EmptyTest;
use MyTester::Tests::Base;

################################################################################

my %tests = (
   unrunTestBatchDiesOnReport_test => sub {
      dies_ok(sub { MyTester::TestBatch->new()->buildReport() },
         "Croak'd when generating a report before cooking");
   },
   
   testBatchGenerateSimpleReport_test => sub {
      my $tb = MyTester::TestBatch->new();
      
      for (10, 20, 30) {
         my $t = MyTester::Tests::Base->new();
         $t->setGrade(
            $MyTester::TestStatus::PASSED, 
            MyTester::Grade->new(msg => "Passed", val => $_));
            
         $tb->addTest($t);
      }
      
      $tb->cookBatch();
      
      my $indentSize = 5;
      my $render = $tb->buildReport()->render($indentSize);
      
      my $renderRegex = qr/
         .*0.*\n
         \ {$indentSize}\(10\):\ Passed\n
         \ {$indentSize}\(20\):\ Passed\n
         \ {$indentSize}\(30\):\ Passed
      /x;
      like($render, $renderRegex, "Generated simple report correctly");
   },
   
   testBatchGeneratedWrappedReport_test => sub {
      my $tb = MyTester::TestBatch->new(
         id => 'myBatch',
         reportColumns => 30);
      
      for (10, 20, 30) {
         my $t = MyTester::Tests::Base->new();
         $t->setGrade(
            $MyTester::TestStatus::PASSED,
            MyTester::Grade->new(msg => "Passed the simple test", val => $_));
         $t->maxStatus($MyTester::TestStatus::PASSED);
         
         $tb->addTest($t);
      }
      
      $tb->cookBatch();
      
      my $indentSize = 3; # Default
      my $render = $tb->buildReport()->render();
      
      my $renderRegex = qr/
         .*myBatch.*\n
            \ {$indentSize}\(10\/10\):\ Passed\ the\ simple\n
            test\n
            \ {$indentSize}\(20\/20\):\ Passed\ the\ simple\n
            test\n
            \ {$indentSize}\(30\/30\):\ Passed\ the\ simple\n
            test
      /x;
      
      like($render, $renderRegex, "Generated wrapped report correctly");
   },
   
   testBatchReportWithDelimiter_test => sub {
      my $tb = MyTester::TestBatch->new(
         id => 'myBatch',
         reportColumns => 30,
         reportWrapLineRegex => qr/: /);
      
      for (10, 20, 30) {
         my $t = MyTester::Tests::Base->new();
         $t->setGrade(
            $MyTester::TestStatus::PASSED,
            MyTester::Grade->new(msg => "Passed the simple test", val => $_));
         $t->maxStatus($MyTester::TestStatus::PASSED);
         
         $tb->addTest($t);
      }
      
      $tb->cookBatch();
      
      my $render = $tb->buildReport()->render();
      
      my $msgTemplate = "   (XX/XX): P";
      my $brokenIndentAmt = index($msgTemplate, ": ") + 2;
      
      my $renderRegex = qr/
         .*myBatch.*\n
         \ {3}\(10\/10\):\ Passed\ the\ simple\n
         \ {$brokenIndentAmt}test\n
         \ {3}\(20\/20\):\ Passed\ the\ simple\n
         \ {$brokenIndentAmt}test\n
         \ {3}\(30\/30\):\ Passed\ the\ simple\n
         \ {$brokenIndentAmt}test
      /x;
      
      like($render, $renderRegex, "Generated wrapped report correctly");
   },
   
   testBatchReportWithUngradeable_test => sub {
      my $tb = MyTester::TestBatch->new(
         id => "batchWithCannotGrades",
         reportWrapLineRegex => qr/: /);
      
      my $canGrade = MyTester::Tests::Base->new(id => "canGrade1");
      $canGrade->setGrade(
         $MyTester::TestStatus::PASSED,
         MyTester::Grade->new(msg => "Passed test that can grade", val => 10));
      $tb->addTest($canGrade);
      
      my $cannotGrade = MyTester::Roles::Mock::EmptyTest->new(id => "!grade");
      $tb->addTest($cannotGrade);
      
      $canGrade = MyTester::Tests::Base->new(id => "canGrade2");
      $canGrade->setGrade(
         $MyTester::TestStatus::PASSED,
         MyTester::Grade->new(msg => "Passed test that can grade", val => 10));
      $tb->addTest($canGrade);
      
      $tb->cookBatch();
      
      my $render = $tb->buildReport()->render();
      
      my $renderRegex = qr/
         .*batchWithCannotGrades.*\n
         \ {3}\(10\):\ Passed\ test\ that\ can\ grade\n
         \ {3}.*?\.\n
         \ {3}\(10\):\ Passed\ test\ that\ can\ grade
      /xs;
      
      like($render, $renderRegex, 
         "Generated dummy report for object w/o CanGrade");
   },
   
   testBatchReportNoHeader_test => sub {
      my $tb = MyTester::TestBatch->new(
         id => "noHeaderBatch",
         reportWithHeader => 0);
      
      my $gradeMsg = "Passed test that can grade";
      my $gradeVal = 10;
      my $canGrade = MyTester::Tests::Base->new(id => "canGrade1");
      $canGrade->setGrade(
         $MyTester::TestStatus::PASSED,
         MyTester::Grade->new(msg => $gradeMsg, val => $gradeVal));
      $tb->addTest($canGrade);
      
      $tb->cookBatch();
      
      my $render = $tb->buildReport()->render();
      my $renderRegex = qr/\($gradeVal\): $gradeMsg/;
      
      like($render, $renderRegex, "Generated report w/ no header");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();