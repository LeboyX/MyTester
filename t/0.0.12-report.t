#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More;

use TryCatch;

use MyTester::Reports::Report;
use MyTester::Reports::ReportLine;
################################################################################

my %tests = (
   renderReport_test => sub {
      my $r = MyTester::Reports::Report->new();
      
      $r->addLines(MyTester::Reports::ReportLine->new(
         line => "I am line 1"));
      $r->addLines(MyTester::Reports::ReportLine->new(
         line => "I am line 2", indent => 1));
      $r->addLines(MyTester::Reports::ReportLine->new(
         line => "I am line 3", indent => 2));
      
      my $render = $r->render();
      
      like($render, qr/I am line 1/, "First line correct");
      like($render, qr/ {3}I am line 2/, "Second line correct");
      like($render, qr/ {6}I am line 3/, "Third line correct");
   },
   
   reportInReport_test => sub {
      my $r = MyTester::Reports::Report->new();
      
      $r->addLines(MyTester::Reports::ReportLine->new(
         line => "I am the only line"));
      $r->catReport($r);
      
      my $render = $r->render();
      like($render, qr/I am the only line\nI am the only line/, 
         "Cat'd report into report");
   },
   
   passColumnsToLines_test => sub {
      my $r = MyTester::Reports::Report->new(columns => 10);
      
      $r->addLines(MyTester::Reports::ReportLine->new(
         line => "I am the only line in this report"));
         
      my $render = $r->render();
      my $renderRegex = qr/
         I\ am\ the\n
         only\ line\n
         in\ this\n
         report
      /x;
      
      like($render, $renderRegex, "Report passed columns down to its lines");
   },
   
   coerceStrToLine_test => sub {
      my $r = MyTester::Reports::Report->new();
      
      my $line = "My line";
      $r->addLines($line);
      
      is($r->bodyLineCount(), 1, "Str coerced to line and added");
      is($r->getLine(0)->line(), $line, "Coerced line had correct line val");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();