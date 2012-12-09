#!perl
package MyTester::Subtypes;
use 5.010;
use Moose::Util::TypeConstraints;

use MyTester::Roles::Testable;

subtype 'TestId', as 'Str';
coerce 'TestId',
   from 'MyTester::Roles::Testable',
   via { $_->id() };
   
1;