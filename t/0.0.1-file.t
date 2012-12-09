#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

use TryCatch;

use File::Temp;

use MyTester::File;

################################################################################

sub badFileTest {
   my $passed = 0;
   try {
      MyTester::File->new(name => "");
   }
   catch ($e) {
      pass("Balked w/ bad file: $e");
      $passed = 1;
   }
   fail ("Didn't balk w/ bad file") if !$passed;
}

sub goodFileTest {
   my $passed = 0;
   my $tmpFile = File::Temp->new();
   try {
      MyTester::File->new(name => $tmpFile->filename);
      $passed = 1;
   }
   catch ($e) {
      fail("Balked w/ good file: $e");
   }
   pass ("Didn't balk w/ good file") if $passed;
}

badFileTest();
goodFileTest();

done_testing();