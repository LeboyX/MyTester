#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use TryCatch;

use MyTester::Reports::ReportLine;
################################################################################

my %tests = (
   indentation_test => sub {
      my $rl = MyTester::Reports::ReportLine->new();
      
      my $line = "I am a line";
      
      $rl->indent(2);
      $rl->line($line);
      
      like($rl->render(), qr/$line/, "Rendered w/ no indent size");
      like($rl->render(1), qr/ {2}$line/, "Rendered w/ indent size '1'");
      like($rl->render(7), qr/ {14}$line/, "Rendered w/ indent size '7'");
   },
   
   wrapping_test => sub {
      my $rl = MyTester::Reports::ReportLine->new();
      
      my @letters = ();
      push(@letters, "aaa") for 1..26;
      my $line = join(" ", @letters);
      
      $rl->line($line);
      $rl->brokenLineIndentation("   ");
      
      my $render = $rl->render();
      
      like($render, qr/(?:aaa ){19}aaa\n/, "Broke line");
      like($render, qr/\n   aaa /, "Wrapped line");
   },
   
   computeBrokenIndentation_test => sub {
      my $rl = MyTester::Reports::ReportLine->new(
         line => "(50/55): Here's the reason why");
      $rl->columns(20);
      
      # + 1 for 0 indexing
      my $expectedAmt = index($rl->line(), ":") + 1; 
      $rl->computeBrokenLineIndentation(qr/:/);
      like($rl->brokenLineIndentation(), qr/^ {$expectedAmt}$/,
         "Computed broken line indentation");
      
      # +2 for 0 indexing and delimiter ":" plus additional " "
      $expectedAmt = index($rl->line(), ":") + 2; 
      $rl->computeBrokenLineIndentation(qr/: /);
      like($rl->brokenLineIndentation, qr/^ {$expectedAmt}$/,
         "Computed broken line indentation at end of delimiter > 1 char");
   },
   
   computeBrokenIndentationError_test => sub {
      my $rl = MyTester::Reports::ReportLine->new(
         line => "(50/55): Here's the reason why");
      $rl->columns(20);
      
      dies_ok(sub { $rl->computeBrokenLineIndentation(qr/y/) }, 
         "Croaks when broken indentation > columns allowed per line");
   },
   
   imports_test => sub {
      use MyTester::Reports::ReportLine qw(generateDummyReportLine);
      
      lives_ok(sub { generateDummyReportLine(); }, 
         "Imported & called generateDummyReportLine()");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();