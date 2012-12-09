#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More;

use Data::Dumper;

use File::Temp;

use MyTester::CompilerForC;
use MyTester::Dir;
use MyTester::File;
use MyTester::ExecEx;
use MyTester::ExecFlag;
use MyTester::TestOven;
use MyTester::TestStatus;

use Time::HiRes qw(time);

use TryCatch;

################################################################################

package ExecAndGrepTest {
   use 5.010;
   use Moose;
   use MooseX::Method::Signatures;
   use Data::Dumper;
   extends qw(MyTester::SimpleTest);
   
   has 'cmd' => (
      isa => 'Str',
      is => 'rw',
      required => 1,
   );
   
   has 'word' => (
      isa => 'Str',
      is => 'rw',
      required => 1,
   );
   
   has 'exec' => (
      isa => 'MyTester::ExecEx',
      is => 'rw',
   );
   
   method test () {
      $self->exec(MyTester::ExecEx->new(cmd => $self->cmd()));
      
      my $h = $self->exec()->buildHarness(t => 5);
      $h->pump();
      $h->finish();
   }
   
   method afterTest () {
      my $word = $self->word();
      if ($self->exec()->derefOut() =~ /$word/i) {
         $self->testStatus($MyTester::TestStatus::PASSED);
      }
      else {
         $self->testStatus($MyTester::TestStatus::FAILED);
      }
   }
   
   method handleFailedProviders {
      $self->fail($MyTester::TestStatus::DEPENDENCY_UNSATISFIED);
   }
   
   with qw(MyTester::Roles::Testable MyTester::Roles::Dependant);
}

my $workingDir = File::Temp->newdir(); # Never unlinks until all testing is done
my $goodFile = qq|
   #include <stdio.h>
   int main (void) {
      printf ("Hello World\\n");
      return 0;
   }
|;
my $badFile = qq|
   #include <stdio.h>
   int main (void) {
      a;
      printf ("Hello World\\n");
      return 0;
   }
|;
my $sleepInterval = 2;
my $sleepFile = qq|
   #include <stdio.h>
   #include <unistd.h>
   int main (void) {
      sleep ($sleepInterval);
      printf ("Hello World\\n");
      return 0;
   }
|;

sub makeCompiler {
   my $workingDir = shift;
   my $fileInput = shift;
   
   my $compiler = MyTester::CompilerForC->new(
      workingDir => MyTester::Dir->new(name => $workingDir));
   $compiler->addFlag(MyTester::ExecFlag->new(name => "ansi"))
      ->addFlag(MyTester::ExecFlag->new(name => "pedantic"))
      ->addFlag(MyTester::ExecFlag->new(name => "Wall"));
   
   my $file = File::Temp->new(dir => $workingDir, UNLINK => 0, SUFFIX => ".c");
   print $file $fileInput;
   $file->flush();
   
   $compiler->addFile(MyTester::File->new(name => $file->filename()));
   
   return $compiler;
}

sub makeTests {
   my ($c, $dependOnC) = @_;
   
   my @ts = (
      ExecAndGrepTest->new(
         id => "t1",
         cmd => $c->getPathToExecutable(),
         word => "Hello"),
      ExecAndGrepTest->new(
         id => "t2",
         cmd => $c->getPathToExecutable(),
         word => "world"));
   if ($dependOnC) {
      for (@ts) {
         $_->addProviders($c);
      }
   }
   return @ts;
}

my %tests = (
   compileAndRunWithSuccess_test => sub {
      my $oven = MyTester::TestOven->new(
         id => "student", assumeDependencies => 1);
         
      my $c = makeCompiler($workingDir->dirname(), $goodFile);
      my @ts = makeTests($c);
      
      $oven->addTest($c);
      $oven->addTestAfter($c, @ts);
      
      is($ts[0]->providerCount(), 1, "Test has new provider");
      
      $oven->cookBatches();
      
      is_deeply($c->testStatus(), $MyTester::TestStatus::PASSED, 
         "Compiler passed");
      ok($c->wasRun(), "Compiler was run");
      
      for my $t (@ts) {
         my $id = $t->id();
         ok($t->wasRun(), "'$id' was run");
         is_deeply($t->testStatus(), $MyTester::TestStatus::PASSED,
            "'$id' passed");
      }
   },
   
   compileAndRunWithFailingTest_test => sub {
      my $oven = MyTester::TestOven->new(assumeDependencies => 1);
      my $c = makeCompiler($workingDir->dirname(), $goodFile);
      my @ts = makeTests($c);
      
      push(@ts, ExecAndGrepTest->new(
         cmd => $c->getPathToExecutable(), 
         word => "HERE",
         id => 't3'));
         
      $oven->addTest($c);
      $oven->addTestAfter($c, @ts);
      
      $oven->cookBatches();
      
      is_deeply($ts[2]->testStatus(), $MyTester::TestStatus::FAILED,
         "Test failed to grep for its word");
   },
   
   compileAndRunWithBadCompile_test => sub {
      my $oven = MyTester::TestOven->new(
         id => "student", assumeDependencies => 1);
         
      my $c = makeCompiler($workingDir->dirname(), $badFile);
      my @ts = makeTests($c);
      
      $oven->addTest($c);
      $oven->addTestAfter($c, @ts);
      $oven->cookBatches();
      
      ok($c->wasRun(), "Compiler was run");
      is_deeply($c->testStatus, $MyTester::TestStatus::FAILED,
         "Compiler failed");
         
      for my $t (@ts) {
         my $id = $t->id();
         ok(!$t->wasRun(), "'$id' wasn't run");
         is_deeply($t->testStatus(), $MyTester::TestStatus::DEPENDENCY_UNSATISFIED,
            "'$id' had unsatisfied dependency");
      }
   },
   
   compileAndRunSequentially_test => sub {
      my $oven = MyTester::TestOven->new(id => "student");
         
      my $c = makeCompiler($workingDir->dirname(), $sleepFile);
      my @ts = makeTests($c, 1);
      
      $oven->addTest($c);
      $oven->addTestAfter($c, $ts[0]);
      $oven->addTestAfter($ts[0], $ts[1]);
      
      my $startTime = time();
      $oven->cookBatches();
      my $endTime = time();
      
      my $targetTime = $sleepInterval * scalar(@ts); # B/c run in sequence
      my $lowerBound = $targetTime - 1.5; # Extra .5s for compile
      my $upperBound = $targetTime + 1.5;
      
      my $time = $endTime - $startTime;
      ok($lowerBound < $time && $time < $upperBound, 
         sprintf("Elapsed time: $lowerBound < %.2fs < $upperBound", $time));
   },
   
   compileAndRunInParallel_test => sub {
      my $oven = MyTester::TestOven->new(id => "student");
         
      my $c = makeCompiler($workingDir->dirname(), $sleepFile);
      my @ts = makeTests($c, 1);
      
      $oven->addTest($c);
      $oven->addTestAfter($c, @ts);
      
      my $startTime = time();
      $oven->cookBatches();
      my $endTime = time();
      
      my $targetTime = $sleepInterval;    # B/c run in parallel
      my $lowerBound = $targetTime - 1.5; # Extra .5s for compile
      my $upperBound = $targetTime + 1.5;
      
      my $time = $endTime - $startTime;
      ok($lowerBound < $time && $time < $upperBound, 
         sprintf("Elapsed time: $lowerBound < %.2fs < $upperBound", $time));
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   subtest $testName => $testCode;
}

done_testing();