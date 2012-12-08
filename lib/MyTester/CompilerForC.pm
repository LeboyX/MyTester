#!/usr/bin/perl
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

our $COMPILE_TO_NAME_FLAG = "o";

our $WARNED = MyTester::TestStatus->new(key => "warned");

################################################################################
# Attributes
################################################################################

has 'workingDir' => (
   isa => 'MyTester::Dir',
   is => 'rw',
   default => sub { return MyTester::Dir->new(name => "./"); }
);

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

has 'compileToName' => (
   isa => 'Str',
   is => 'rw',
   default => "a.out",
   trigger => sub {
      my ($self, $val) = @_;
      croak "'compileToName' cannot be empty string" if length($val) < 1;
   }
);

has 'compileReturnStatus' => (
   isa => 'Int',
   is => 'ro',
   writer => '_compileReturnStatus'
);

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

method getPathToExecutable () {
   my $dir = $self->workingDir()->name();
   if ($dir !~ /\/\s*$/) {
      $dir .= "/";
   }
   
   return $dir.$self->compileToName();
}

method beforeTest () {
   return $self;
}

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

with qw(MyTester::Roles::Testable);

1;