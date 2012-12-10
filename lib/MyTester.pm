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

=head1 Description

Originally, I graded student code submissions using an often last-minute-patched
version of this module that, while very useful, sometimes proved too laborious
due to its inflexibility and lack of foresight during the initial design. 

This is a re-write of my original module, using L<Moose> to make OO perl5 
cleaner to use.

This module (and all others contained w/in it) aims to make that proces easier
providing generic, easily extended and re-used tests, wrappers, and methods
of parallelisation to make grading code submissions easier/faster/cleaner. This
module does not leverage the TAP interface of any of the Test::* modules. It's
all written from scratch. 

While this module is I<intended> for testing/grading code submissions, there
is no restriction on what you can do. If written properly, it should be 
applicable to most testing circumstances in one form or another. 

=head1

TODO: More to follow
