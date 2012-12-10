#!/usr/bin/perl 
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use MyTester;

my @classes = qw(
   CompilerForC ExecEx ExecFlag File Grade Subtypes TestBatch TestOven 
   TestStatus 
);
my @roles = qw(
   CanGrade Identifiable Testable Provider Dependant
);
my @tests = qw(
   Base ExecGrep
);
plan tests => 
   (scalar @classes) +
   (scalar @tests) +
   (scalar @roles) + 1;

use_ok( 'MyTester' ) || print "Bail out!\n";
for my $class (@classes) {
   use_ok("MyTester::$class") || print "Bail out!\n";
}

for my $role (@roles) {
   use_ok("MyTester::Roles::$role") || print "Bail out!\n";
}

for my $test (@tests) {
   use_ok("MyTester::Tests::$test") || print "Bail out!\n";
}