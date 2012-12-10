#!perl

=pod

=head1 Name

MyTester::Subtypes - Where all subtypes and definitions fo the MyTester proejct
are defined

=head1 Version

No set version right now

=cut

package MyTester::Subtypes;
use 5.010;
use Moose::Util::TypeConstraints;

use MyTester::TestStatus;
use MyTester::Roles::Testable;

=pod

=head1 Subtypes

=head2 TestId

   subtype 'TestId', as 'Str';
   coerce 'TestId',
      from 'MyTester::Roles::Testable',
      via { $_->id() };
      
Wrapped the id of a test by letting you either 1) Use the test's id explicitly
(which is already a Str) or 2) Use the L<MyTester::Roles::Testable> object 
itself and let the coercion defined here do the work for you.

=cut

subtype 'TestId', as 'Str';
coerce 'TestId',
   from 'MyTester::Roles::Testable',
   via { $_->id() };

=pod

=head2 TestStatusKey

   subtype 'TestStatusKey', as 'Str';
   coerce 'TestStatusKey',
      from 'MyTester::TestStatus',
      via { $_->key(); };

Wraps the key of a L<MyTester::TestStatus> by either 1) Using the object or 2) 
Passing in its key. The coercion will the former to its key, so you don't have
to think about it when passing it around.

=cut

subtype 'TestStatusKey', as 'Str';
coerce 'TestStatusKey',
   from 'MyTester::TestStatus',
   via { $_->key(); };
1;