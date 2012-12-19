#!perl
use Modern::Perl '2012';

use Data::Dumper;

use Test::More;

use TryCatch;

use MyTester::ExecEx;
use MyTester::TestBatch;
use MyTester::Tests::ExecGrep;
################################################################################

my %tests = (
   basicEchoAndGrep_test => sub {
      my $t = MyTester::Tests::ExecGrep->new(
         exec => MyTester::ExecEx->new(cmd => 'echo'),
         regex => "qr/hello/;");
      
      my $strToEcho = "hello world";
      $t->addArg($strToEcho);
      $t->test();
      
      is_deeply($t->testStatus(), $MyTester::TestStatus::PASSED,
         "Test passed when its regex matched");
         
      chomp(my $output = $t->out());
      is($output, $strToEcho, "Captured output");
   },
   
   failEchoAndGrep_test => sub {
      my $t = MyTester::Tests::ExecGrep->new(
         exec => MyTester::ExecEx->new(cmd => 'echo'),
         regex => "qr/hello/;");
      
      $t->addArg("goodbye world");
      $t->test();
      
      is_deeply($t->testStatus(), $MyTester::TestStatus::FAILED,
         "Test failed when its regex didn't match");
   }
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();