#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More;

use TryCatch;

use MyTester::ExecEx;
################################################################################

my %tests = (
   multiAddFlagTest => sub {
      my $x = MyTester::ExecEx->new(cmd => "echo");
      
      my $startingFlagCount = $x->flagCount();
      
      my $e = MyTester::ExecFlag->new(name => "e");
      my $p = MyTester::ExecFlag->new(name => "p");
      
      $x->addFlag($e)->addFlag($p);
        
      is($x->flagCount() - $startingFlagCount, 2, "2 flags added");
      
      for my $flag ($e, $p) {
         my $name = $flag->name();
         is_deeply($x->getFlag($name), $flag, "Found $name flag by name");
         is_deeply($x->getFlag($flag), $flag, "Found $name flag by obj");
      }
   },
   
   timeoutTest => sub {
      my $x = MyTester::ExecEx->new(cmd => "sleep");
      $x->addArg("3");
      
      my $h = $x->buildHarness(t => 1);
      
      my $passed = 0;
      try {
         $h->start();
         $h->finish();
      }
      catch ($e where { /timeout/ }) {
         pass ("Timed out: $e");
         $passed = 1;
      }
      
      if (!$passed) {
         fail ("Didn't time out");
      }
   },
   
   stdoutStdinTest => sub {
      my $in = "Hello World!";
      
      my $x = MyTester::ExecEx->new(cmd => "cat", in => \$in);
      my $h = $x->buildHarness();
      
      $h->pump();
      $h->finish();
      
      is($x->derefOut(), "Hello World!", "Command directed IO well");
   },
   
   signalTest => sub {
      my $x = MyTester::ExecEx->new(cmd => "sleep");
      $x->addArg("10");
      
      my $h = $x->buildHarness();
      $h->start();
      $h->signal("INT");
      $h->finish();
      
      my $fullResult = $h->full_result();
      isnt($fullResult, 0, "Cmd died from non-zero signal code '$fullResult'");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();