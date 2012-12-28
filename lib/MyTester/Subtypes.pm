#!perl

=pod

=head1 Name

MyTester::Subtypes - Where [almost] all subtypes and definitions of the MyTester
proejct are defined. The "basic" subtypes and coercions live here. 

=head1 Version

No set version right now

=head1 Caveats

While L<Moose::Manual::BestPractices> recommends all subtypes in one module, 
this could not be done for the MyTester project. The following is a list of the
locations of all other, more specific subtype/coercion definitions:

=over

=item * L<MyTester::Reports::ReportLine>: Defines subtypes to make it easier
to make a [list of] L<ReportLine|MyTester::Reports::ReportLine> objects by just 
passing Str's around

=back

=cut

package MyTester::Subtypes;
use Modern::Perl '2012';
use Moose::Util::TypeConstraints;

use MyTester::TestStatus;
use MyTester::Roles::Testable;
use MyTester::Roles::Dependant;

=pod

=head1 Subtypes

=head2 TestId

   subtype 'TestId', as 'Str';
   coerce 'TestId',
      from 'MyTester::Roles::Testable',
      via { $_->id() };
      
Wraps the id of a test by letting you either 1) Use the test's id explicitly
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

=pod

=head2 PositiveInt

   subtype 'PositiveInt', 
      as 'Int', 
      where { $_ > -1 },
      message { "Number must be > -1" };
   
   An int w/ the constraint that it must be > -1

=cut

subtype 'PositiveInt', 
   as 'Int', 
   where { $_ > -1 },
   message { "Number must be > -1" };

=pod

=head2 MyTester::QuickId

   subtype 'MyTester::QuickId', as 'Str';
   coerce 'MyTester::QuickId',
      from 'MyTester::Roles::Identifiable',
      via { $_->id(); };

A trivial convenience subtype to simplify extracting id's from 
L<identifiable|MyTester::Roles::Identifiable> classes.

=cut

subtype 'MyTester::QuickId', as 'Str';
coerce 'MyTester::QuickId',
   from 'MyTester::Roles::Identifiable',
   via { $_->id(); };

1;
