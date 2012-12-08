#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More;

use TryCatch;

use File::Temp;

use MyTester::Dir;

################################################################################

sub badDirTest {
   my $passed = 0;
   try {
      MyTester::Dir->new(name => "");
   }
   catch ($e) {
      chomp $e;
      pass ("Balked w/ bad dir: '$e'");
      $passed = 1;
   }
   fail ("Didn't balk w/ bad dir") if !$passed;
}

sub goodDirTest {
   my $passed = 0;
   my $tmpDir = File::Temp->newdir();
   try {
      MyTester::Dir->new(name => $tmpDir->dirname());
      $passed = 1;
   }
   catch ($e) {
      chomp $e;
      fail ("Balked w/ good dir: '$e'");
   }
   pass ("Didn't balk w/ good dir") if $passed;
}

badDirTest();
goodDirTest();

done_testing();