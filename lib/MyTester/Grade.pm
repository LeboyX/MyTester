#!perl

=pod

=head1 Name

MyTester::Grade - wraps a test score w/ an message explaning what the score
means

=head1 Version

No set version right now

=head1 Synopsis

   package GradeableTest;
   
   use Moose;
   with qw(MyTester::Roles::CanGrade);
   
   my $t = GradeableTest->new(rubric => {
      passed => MyTester::Grade->new(
         val => 100,
         msg => "You passed"),
         
      passedWithWarnings => MyTester::Grade->new(
         val => 90,
         msg => "Passed, but you had some warnings");
         
      failed => MyTester::Grade->new(
         val => 0,
         msg => "You failed this test");
   });

=head1 Description

Used conjunction w/ L<MyTester::Roles::CanGrade> to define a mapping between
status keys and scores/messages to give in response to those keys. 

=cut

package MyTester::Grade;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 val

   has 'val' => (
      isa => 'Num',
      required => 1,
      is => 'rw'
   );

The point value for this grade

=cut

has 'val' => (
   isa => 'Num',
   required => 1,
   is => 'rw'
);

=pod

=head2 msg

   has 'msg' => (
      isa => "Str",
      required => 1,
      is => 'rw'
   );
   
The message explaining the meaning of this particular C<MyTester::Grade> 
instance

=cut

has 'msg' => (
   isa => "Str",
   required => 1,
   is => 'rw'
);

################################################################################
# Methods
################################################################################

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################


1;