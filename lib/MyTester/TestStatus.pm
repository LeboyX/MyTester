#!/usr/bin/perl
package MyTester::TestStatus;
use Moose;

has key => (
   isa => 'Str',
   is => 'rw'
);

has msg => (
   isa => 'Str',
   is => 'rw'
);

our MyTester::TestStatus $UNSTARTED = MyTester::TestStatus->new(
   key => "unstarted",
   msg => "Test has not yet been started"
);

our MyTester::TestStatus $BEGUN = MyTester::TestStatus->new(
   key => "begun",
   msg => "Test has begun"
);

our MyTester::TestStatus $PENDING_EVAL = MyTester::TestStatus->new(
   key => "pending_eval",
   msg => "Test was run and is pending evaluation"
);

our MyTester::TestStatus $PASSED = MyTester::TestStatus->new(
   key => "passed",
   msg => "Test passed"
);

our MyTester::TestStatus $FAILED = MyTester::TestStatus->new(
   key => "failed",
   msg => "Test failed"
);

our MyTester::TestStatus $DEPENDENCY_UNSATISFIED = MyTester::TestStatus->new(
   key => "dependency_unsatisfied",
   msg => "Dependency unsatisfied"
);

1;
