#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More;

use TryCatch;

use Data::Dumper;

use File::Temp;
use File::Basename qw(fileparse);

use MyTester::CompilerForC;
use MyTester::Dir;
################################################################################

my %tests = (
   testBadCompiler => sub {
      try {
         MyTester::CompilerForC->new()->compiler("");
      }
      catch ($e) {
         chomp $e;
         pass("Balked w/ bad compiler: '$e'");
         return;
      }
      fail ("Didn't balk w/ bad compiler");
   },
   
   testFileDefaults => sub {
      ok(!MyTester::CompilerForC->new()->hasFiles(), "Starts w/ no files");
   },
   
   testDirDefaults => sub {
      is_deeply(
         MyTester::CompilerForC->new()->workingDir(),
         MyTester::Dir->new(name => "./"),
         "Default working dir is './'");
   },
   
   addFilesTest => sub {
      my $c = MyTester::CompilerForC->new();
      
      my $numFiles = 3;
      for (1..$numFiles) {
         $c->addFile(
            MyTester::File->new(name => File::Temp->new()->filename()));
      }
      
      is($c->getFiles(), $numFiles, "Has '$numFiles' recorded files");
   },
   
   compileNameFlagTest => sub {
      my $c = MyTester::CompilerForC->new(compileToName => "myExec");
      my $flag = $c->getFlag($MyTester::CompilerForC::COMPILE_TO_NAME_FLAG);
      
      is_deeply($flag->args(), ["./myExec"], "Compiler setup -o param");
      is($flag->isLong(), 0, "Compiler -o flag is short");
   },
   
   compileSimpleFileTest => sub {
      my $dir = File::Temp->newdir();
      my $c = MyTester::CompilerForC->new(
         workingDir => MyTester::Dir->new(name => $dir->dirname()));
      
      my $file = File::Temp->new(SUFFIX => ".c");
      my $simpleCFile = qq /
         #include <stdio.h>
         int main (void) {
            printf("Hello world!\\n");
            
            return 0;
         }
      /;
      
      print $file $simpleCFile;
      $file->flush();
      
      $c->addFile(MyTester::File->new(name => $file->filename()));
      
      $c->test();
      my $execFilePath = $c->getPathToExecutable();
      ok(-f -x $execFilePath, "File '$execFilePath' compiled as executable");
      is($c->compileReturnStatus(), 0, "Return status 0");
      
      is_deeply($c->testStatus(), $MyTester::TestStatus::PASSED, 
         "Test has passed status");
   },
   
   compileBadSimpleFileTest => sub {
      my $dir = File::Temp->newdir();
      my $c = MyTester::CompilerForC->new(
         workingDir => MyTester::Dir->new(name => $dir->dirname()));
      
      my $file = File::Temp->new(SUFFIX => ".c");
      my $simpleCFile = qq |
         #include <stdio.h>
         int main (void) {
            printf("Hello world!\\n");c /* <-- 'c' does not belong */
            
            return 0;
         }
      |;
      
      print $file $simpleCFile;
      $file->flush();
      
      $c->addFile(MyTester::File->new(name => $file->filename()));
      
      $c->test();
      
      my $execFilePath = $c->getPathToExecutable();
      ok(!-f $execFilePath, "File '$execFilePath' failed to compile");
      ok(${$c->compileErr()} =~ /error/i, "Compile error output present");
      isnt($c->compileReturnStatus(), 0, "Compile had non-zero return");
      
      is_deeply($c->testStatus(), $MyTester::TestStatus::FAILED, 
         "Test has failed status");
      
   }
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();