#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use List::Util qw(sum);

use Test::Exception;
use Test::More;
use Test::Warn;

use TryCatch;

use MyTester::Roles::TrackScores;
################################################################################

package SimpleTracker {
   use Moose;
   
   with qw(MyTester::Roles::TrackScores);
}

my %tests = (
   scoreAdding_test => sub {
      my $t = SimpleTracker->new();
      
      my @scores = (10, 20, 30, -15);
      for (@scores) {
         $t->addScore("score_".$_, $_);
      }
      
      my $expectedSum = sum(@scores);
      is($t->earned(), $expectedSum, "Tracked score sum");
   },
   
   maxTooLow_test => sub {
      my $t = SimpleTracker->new();
      
      $t->addScore("score1", 10);
      throws_ok(sub { $t->max(9) }, qr/9.*cannot be less than.*10/, 
         "Croak w/ too-low max");
      
      $t->max(10);
      warning_like { $t->addScore("score2", 1) } qr/11.*>.*10/, 
         "Warning when sum > max";
         
      is($t->max(), 11, "Max adjusted");
   },
   
   scoreOverwrite_test => sub {
      my $t = SimpleTracker->new();
      
      $t->addScore("score1", 10);
      
      $t->addScore("score1", 5);
      is($t->getScore("score1"), 5, "Overwrote old score goind down");
      is($t->earned(), 5, "Overwrite adjusted earned");
      
      $t->addScore("score1", 7);
      is($t->getScore("score1"), 7, "Overwrote old score going up");
      is($t->earned(), 7, "Overwrite adjusted earned");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();
