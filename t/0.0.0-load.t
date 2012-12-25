#!/usr/bin/perl 
use Modern::Perl '2012';
use Test::More;
use MyTester;

my @classes = qw(
   CompilerForC ExecEx ExecFlag File Grade Subtypes TestBatch TestOven 
   TestStatus 
);
my @roles = qw(
   CanGrade Identifiable Testable Provider Dependant GenReport
);
my @tests = qw(
   Base ExecGrep
);
my @reports = qw(
   Report ReportLine
);
plan tests => 
   (scalar @classes) +
   (scalar @tests) +
   (scalar @roles) +
   (scalar @reports) +  1;

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

for my $report (@reports) {
   use_ok("MyTester::Reports::$report") || print "Bail out!\n";
}