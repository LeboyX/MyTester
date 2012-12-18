#!/usr/bin/perl
package MyTester;
use Moose;
our $VERSION = "0.0.1";

our $TEST_POD_COVERAGE = 1;

1;

__END__

=head1 Name

MyTester - A module to make make the testing/scoring/grade-file-generating
of code submissions easier.

=head1 Version

Version 0.0.1

=head1 To Install

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

=head1 Synopsis

   my $testSuite = MyTester::TestOven->new(assumeDependencies => 1);

   # Flags are not long be default
   my $compiler = MyTester::CompilerForC->new();
   $compiler->addFlag(MyTester::ExecFlag->new(name => "ansi", isLong => 0));
   $compiler->addFlag(MyTester::ExecFlag->new(name => "pedantic"));
   $compiler->addFlag(MyTester::ExecFlag->new(name => "Wall"));
   
   $compiler->workingDir(MyTester::Dir->new()); # Defaults to './'
   $compiler->addFile(MyTester::File->new(name => "main.c"));
   
   $testSuite->addTest($compiler);
   
   # Runs a given executable and looks for output
   my $helloFinderTest = MyTester::Tests::ExecGrep->new(regex => "qr/hello/");
   my $worldFinderTest = MyTester::Tests::ExecGrep->new(regex => "qr/World/i");
   
   for ($helloFinderTest, $worldFinderTest) {
      $_->cmd($compiler->getPathToExecutable);
      
      # Grade if we find the word
      $_->setGrade(
         $MyTester::TestStatus::PASSED, 
         MyTester::Grade->new(val => "10", msg => "We found our word"));
         
      # Grade if we don't
      $_->setGrade(
         $MyTester::TestStatus::FAILED,
         MyTester::Grade->new(val => "0", msg => "Didn't found our word"));
      
      #
      # For tests w/ more grade options, this is more useful. For now, it's just
      # telling the test what the maximum, best possible outcome it
      # 
      $_->maxStatus($MyTester::TestStatus::PASSED");
   }
   
   #
   # W/ assuming dependencies, if $compiler fails, tests added after it won't 
   # run
   #
   $testSuite->addTestAfter($compiler, $helloFinderTest);
   
   #
   # No dependency is created here - we're just adding tests w/ no reference
   # to others. So, if $compiler fails, this test will still run. (This isn't
   # good, but it illustrates functionality).
   #
   $testSuite->addTest($worldFinderTest);
   
   $testOven->cookBatches();
   
   #TODO: Show how to generate a report

=head1 Description

Originally, I graded student code submissions using an often last-minute-patched
version of this module that, while very useful, sometimes proved too laborious
due to its inflexibility and lack of foresight during the initial design. 

This is a re-write of my original module, using L<Moose> to make OO perl5 
cleaner to use.

This module (and all others contained w/in it) aims to make the proces easier
by providing generic, easily extended and re-used tests, wrappers, and methods
of parallelisation to make grading code submissions easier/faster/cleaner. This
module does not leverage the TAP interface of any of the Test::* modules. It's
all written from scratch. 

While this module is I<intended> for testing/grading code submissions, there
is no restriction on what you can do. If written properly, it should be 
applicable to most testing circumstances in one form or another. 

=head1

TODO: More to follow
