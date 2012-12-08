#!/usr/bin/perl

=pod

=head1 Name

MyTester::CompilerForC - Consumer of L<MyTester::Roles::Testable> designed to 
compile code into an executable.

=head1 Version

No set version right now

=head1 Synopsis

   my $dir = File::Temp->newdir();
   my $c = MyTester::CompilerForC->new(
      workingDir => MyTester::Dir->new(name => $dir->dirname()));
   
   #
   # Realistically, this would represent an actual .c source file
   #
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
   
   $c->test(); # On success, will give us 'a.out' in 'workingDir'

=head1 Description

Designed to be part of a test suite for testing/grading code submissions. By
making this test the first in a series of tests (see L<MyTester::TestOven>), you
can write tests to exercise the program compiled w/ this test.

On failure, dependant tests can choose not to be run b/c compilation failed.

=head1 TODOs

=over 

=item * Make this class consume L<MyTester::Roles::Provider>, so other tests
can depend on it.

=back

=cut

package MyTester::CompilerForC;
use 5.010;
use Moose;
extends 'MyTester::SimpleTest';

use MooseX::Method::Signatures;
use MooseX::StrictConstructor;
use MooseX::Privacy;

################################################################################
# Imports
################################################################################
use MyTester::File;
use MyTester::Dir;
use MyTester::ExecEx;
use MyTester::ExecFlag;
use MyTester::TestStatus;

use autodie qw(:system open); 

use Carp;
use Data::Dumper;
use TryCatch;

use File::Which;

use IPC::Run;

use POSIX qw (SIGINT);

################################################################################
# Constants
################################################################################

=pod

=head1 Constants

=over

=item * B<$COMPILE_TO_NAME_FLAG> = "o": flag passed to compiler to name the 
executable we compile

=cut

our $COMPILE_TO_NAME_FLAG = "o";

=pod

=item * B<$WARNED> = MyTester::TestStatus->new(key => "warned"): a 
L<MyTester::TestStatus> object representing a compilation which succeeded but
had warnings

=back

=cut

our $WARNED = MyTester::TestStatus->new(key => "warned");

################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 workingDir

   has 'workingDir' => (
      isa => 'MyTester::Dir',
      is => 'rw',
      default => sub { return MyTester::Dir->new(name => "./"); }
   );
   
Where your source files are and where you plan to drop the executable once
compiled.

=cut
   
has 'workingDir' => (
   isa => 'MyTester::Dir',
   is => 'rw',
   default => sub { return MyTester::Dir->new(name => "./"); }
);

=head2 files

   has 'files' => (
      isa => 'ArrayRef[MyTester::File]',
      traits => [qw(Array)],
      is => 'rw',
      default => sub { [] },
      handles => {
         addFile => 'push',
         getFiles => 'elements',
         hasFiles => 'count'
      }
   );

List of files you want to compile. These can be .c, .h, .o, etc. Anything the
compiler will accept is valid. They'll be passed to the compiler in the order
added.

=cut

has 'files' => (
   isa => 'ArrayRef[MyTester::File]',
   traits => [qw(Array)],
   is => 'rw',
   default => sub { [] },
   handles => {
      addFile => 'push',
      getFiles => 'elements',
      hasFiles => 'count'
   }
);

=pod

=head2 compileToName

   has 'compileToName' => (
      isa => 'Str',
      is => 'rw',
      default => "a.out",
      trigger => sub {
         my ($self, $val) = @_;
         croak "'compileToName' cannot be empty string" if length($val) < 1;
      }
   );

Name to compile the executable to. If you're planning on generating a .o file
or something other than a simple executable, you should set this appropriately.

B<NOTE:> If you don't want your compiled program to be 'a.out', you MUST set it
at object construction. L<MyTester::ExecEx> doesn't yet support removing
flags/

=cut

has 'compileToName' => (
   isa => 'Str',
   is => 'rw',
   default => "a.out",
   trigger => sub {
      my ($self, $val) = @_;
      croak "'compileToName' cannot be empty string" if length($val) < 1;
   }
);

=pod

=head2 compileReturnStatus

   has 'compileReturnStatus' => (
      isa => 'Int',
      is => 'ro',
   );

The status of the compilation command as returned from the command line. 

=cut

has 'compileReturnStatus' => (
   isa => 'Int',
   is => 'ro',
   writer => '_compileReturnStatus'
);

=pod

=head2 exec

   has 'exec' => (
      isa => 'MyTester::ExecEx',
      is => 'ro',
      default => sub { MyTester::ExecEx->new(cmd => "gcc") },
      handles => {
         addFlag => 'addFlag',
         getFlag => 'getFlag',
         getAllFlags => 'getAllFlags',
         flagCount => 'flagCount',
         hasFlags => 'hasFlags',
         compiler => 'cmd',
         compileOut => 'out',
         compileErr => 'err'
      }
   );

Where most of the magic happens. We delegate down to L<MyTester::ExecEx> for a
lot of the heavy lifting for executing our compile, adding flags to the compile,
setting the comipler we're going to use (i.e. 'gcc'), etc. 

Here, you should care most about the delegations. See the documentation on 
L<MyTester::ExecEx> for more details on what to do w/ this object.

=cut

has 'exec' => (
   isa => 'MyTester::ExecEx',
   is => 'ro',
   default => sub { MyTester::ExecEx->new(cmd => "gcc") },
   handles => {
      addFlag => 'addFlag',
      getFlag => 'getFlag',
      getAllFlags => 'getAllFlags',
      flagCount => 'flagCount',
      hasFlags => 'hasFlags',
      compiler => 'cmd',
      compileOut => 'out',
      compileErr => 'err'
   }
);

################################################################################
# Construction
################################################################################

=head1 Construction

=head2 BUILD

Adds the "-o compileToName' flag to our C<exec> object. 

=cut

sub BUILD {
   my $self = shift;
   
   my $compileToNameFlag = MyTester::ExecFlag->new(
      name => $COMPILE_TO_NAME_FLAG, 
      args => [$self->getPathToExecutable()]); 
   $self->addFlag($compileToNameFlag);
}

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 getPathToExecutable

B<Returns:> The path to the executable we'll be compiling to (i.e. 
"/path/to/your/dir/a.out"). Note that, prior to running this test, the 
executable will not exist yet. 

=cut

method getPathToExecutable () {
   my $dir = $self->workingDir()->name();
   if ($dir !~ /\/\s*$/) {
      $dir .= "/";
   }
   
   return $dir.$self->compileToName();
}

=pod

=head2 beforeTest

Does nothing. Will call child class' implementations, if they have them

B<Returns:> $self

=cut

method beforeTest () {
   inner();
   return $self;
}

=pod

=head2 test

Actually runs the test - compiles all the sources files you gave. Will also
set L</compileReturnStatus> after compilation has run

B<Returns:> $self

=cut

method test () {
   my $h = $self->_setupCompileCall();
   $h->pump();
   $h->finish();
   
   $self->_compileReturnStatus(int($h->result()));
   
   return $self;
}

method _setupCompileCall () {
   my $ex = $self->exec();
   $ex->addArgs(map { $_->name() } $self->getFiles());
   
   return $ex->buildHarness();
}

=pod

=head2 afterTest

Will set C<testStatus> to one of the following given the respective condition:

=over

=item * $MyTester::TestStatus::PASSED: If compile returned success (0)

=item * $WARNED: If compile succeeded, but had warnings in its output

=item * $MyTester::TestStatus::FAILED: If comiple had !0 return and errors in
its output

=back

B<Returns:> $self

=cut

method afterTest () {
   if (!$self->compileReturnStatus()) {
      $self->testStatus($MyTester::TestStatus::PASSED);
   }
   else {
      my $out = $self->compileOut();
      if ($out !~ /error/i && $out =~ /warn/i) {
         $self->testStatus($WARNED);
      }
      else {
         $self->testStatus($MyTester::TestStatus::FAILED);
      }
   }
   
   return $self;
}

################################################################################
# Roles (included at end to compile properly)
################################################################################

=pod

=head1 Roles Consumed

=over

=item * L<MyTester::Roles::Testable>

=back

=cut

with qw(MyTester::Roles::Testable);

1;