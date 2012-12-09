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

use TryCatch;

################################################################################

package ExecAndGrepTest {
   use 5.010;
   use Moose;
   use MooseX::Method::Signatures;
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
      if ($self->exec()->derefOut() =~ /hello/i) {
         $self->testStatus($MyTester::TestStatus::PASSED);
      }
      else {
         $self->testStatus($MyTester::TestStatus::FAILED);
      }
   }
   
   with qw(MyTester::Roles::Testable);
}

my %tests = (
   integrateOvenTest => sub {
      my $workingDir = File::Temp->newdir();
      
      my $oven = MyTester::TestOven->new(
         id => "student", assumeDependencies => 1);
         
      my $c = makeCompiler($workingDir->dirname());
      $oven->addTest($c);
      
      my $t = ExecAndGrepTest->new(
         cmd => $c->getPathToExecutable(),
         word => "Hello");
         
      $oven->addTestAfter($c, $t);
      $oven->cookBatches();
      
      is_deeply($t->testStatus(), $MyTester::TestStatus::PASSED,
         "ExecAndGrepTest passed");
   }
);

sub makeCompiler {
   my $workingDir = shift;
   
   my $compiler = MyTester::CompilerForC->new(
      workingDir => MyTester::Dir->new(name => $workingDir));
   $compiler->addFlag(MyTester::ExecFlag->new(name => "ansi"))
      ->addFlag(MyTester::ExecFlag->new(name => "pedantic"))
      ->addFlag(MyTester::ExecFlag->new(name => "Wall"));
   
   my $file = File::Temp->new(dir => $workingDir, UNLINK => 0, SUFFIX => ".c");
   my $fileContents = qq|
      #include <stdio.h>
      int main (void) {
         printf ("Hello World\\n");
         
         return 0;
      }
   |;
   print $file $fileContents;
   $file->flush();
   
   $compiler->addFile(MyTester::File->new(name => $file->filename()));
   
   return $compiler;
}

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();