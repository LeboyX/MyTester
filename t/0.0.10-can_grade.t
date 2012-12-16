#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Test::Trap;

use TryCatch;

use MyTester::Grade;
use MyTester::TestStatus;
use MyTester::Roles::CanGrade;
################################################################################

package Grader {
   use Moose;
   
   with qw(MyTester::Roles::CanGrade);
}

my %tests = (
   report_test => sub {
      my $grader = Grader->new();
      
      my $goodStatus = $MyTester::TestStatus::PASSED;
      my $badStatus = $MyTester::TestStatus::FAILED;
      
      my $goodGrade = MyTester::Grade->new(val => 50, msg => "Good");
      my $badGrade = MyTester::Grade->new(val => 25, msg => "Bad");
      
      $grader->setGrade($goodStatus, $goodGrade)
         ->setGrade($badStatus, $badGrade);
      $grader->maxStatus($goodStatus);
      
      
      like($grader->genReport($goodStatus)->getLine(0)->line(), qr/50\/50.*Good/,
         "Grader generated good report correctly");
      like($grader->genReport($badStatus)->getLine(0)->line(), qr/25\/50.*Bad/,
         "Grader generated bad report correctly");
         
      like($grader->genReport($badStatus, $badStatus)->getLine(0)->line(), 
         qr/25\/25.*Bad/,
         "Grader generated bad report w/ bad as max");
   },
   
   warnBadMax_test => sub {
      my $grader = Grader->new();
      
      my $badStatus = $MyTester::TestStatus::FAILED;
      
      my $goodStatus = $MyTester::TestStatus::PASSED;
      my $goodGrade = MyTester::Grade->new(val => 50, msg => "Good");
      $grader->setGrade($goodStatus, $goodGrade);
      
      my $r = trap { $grader->genReport($goodStatus, $badStatus)};
      ok($trap->stderr, "Warning emitted for bad max status");
      
      like($r->getLine(0)->line(), qr/50[^\/].*Good/, 
         "Still generated correct report");

   },
   
   errorBadStatus_test => sub {
      my $grader = Grader->new();
      
      my $badStatus = $MyTester::TestStatus::FAILED;
      
      dies_ok(sub { $grader->maxStatus($badStatus); }, 
         "Dies when set max had no mapping");
      dies_ok(sub { $grader->genReport($badStatus); },
         "Dies when generating report for status w/ no mapping");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();