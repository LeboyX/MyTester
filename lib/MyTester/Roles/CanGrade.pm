#!perl

=pod

=head1 Name

MyTester::Roles::CanGrade - Role to define how scores are determined and 
explanatory messages for those scores are given

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
   
   # Do other things w/ your test
   
   print $t->getGrade()->msg()."\n"; # Prints msg for whatever grade we should 
                                     # give the test after processing it 

=head1 Description

Must used in combination w/ L<MyTester::TestStatus> objects.

Provides a map of status keys to make it easier to provide a score and 
explanatory message about it. The keys you use will/should likely be the C<key>
attribute for whatever L<MyTester::TestStatus> classes your test uses. 

=head1 TODO's

=over

=item * Add translation of L<MyTester::TestStatus> objects in C<setGrade> in 
same way that C<getGrade> currently does

=back

=cut

package MyTester::Roles::CanGrade;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use MyTester::Grade;
use MyTester::Subtypes;
################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 rubric

has 'rubric' => (
   isa => 'HashRef[MyTester::Grade]',
   traits => [qw(Hash)],
   is => 'rw',
   default => sub { {} },
   handles => {
      setGrade => 'set',
   }
);

Mapping of test status keys to grades.

=head3 Notes

=over

=item * L<MyTester::TestStatus> objects are converted to their 'key' value 
before actually calling C<getGrade>. This kind of translations is B<not> done in 
C<setGrade>.

=back

=cut

has 'rubric' => (
   isa => 'HashRef[MyTester::Grade]',
   traits => [qw(Hash)],
   is => 'rw',
   default => sub { {} },
   handles => {
      _setGrade => 'set',
      _getGrade => 'get',
      _hasGrade => 'exists'
   }
);

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 hasGrade

B<Parameters>

=over

=item [0](<MyTester::SimpleTest/TestStatusKey>): key for status to check 

=back

B<Returns:> whether we have a grade for the specified test status or not.

=cut

method hasGrade (TestStatusKey $id! does doerce) {
   return $self->_hadGrade($id);
}

=pod

=head2 getGrade

B<Parameters>

=over

=item [0](<MyTester::SimpleTest/TestStatusKey>): key for status to get

=back

B<Returns:> the L<MyTester::Grade> object associated w/ the test status key you
passed in. Can be undef if we don't have it in the rubric.

=cut

method getGrade (TestStatusKey $id! does coerce) {
   return $self->_getGrade($id);
}

=pod

=head2 setGrade

Sets a test status to map to a given grade. 

B<Parameters>

=over

=item [0](L<MyTester::Subtypes/TestStatusKey>): Key of test status to make grade
mapping for

=item [1](L<MyTester::Grade>): grade to map the status to

=back

B<Returns:> C<$self>

=cut

method setGrade (TestStatusKey $id! does coerce, MyTester::Grade $grade!) {
   $self->_setGrade($id => $grade);
   return $self;
}

=pod

=head2 getGradeMsg

Conveniene method to directly retrieve the grade msg associated w/ a particular
L<MyTester::TestStatus>.

B<Parameters>

=over

=item * [0]: The L<MyTester::TestStatus> object whose msg you wish to retrieve. 

=back

B<Returns:> The msg associated w/ the provided status. Can be undef if you 
didn't map the given status to a grade in the C<rubric>.

=cut

method getGradeMsg (MyTester::TestStatus $testStatus) {
   return $self->getGrade($testStatus)->msg();
}

=pod

=head2 getGradeVal

Conveniene method to directly retrieve the grade val associated w/ a particular
L<MyTester::TestStatus>.

B<Parameters>

=over

=item * [0]: The L<MyTester::TestStatus> object whose val you wish to retrieve.

=back 

B<Returns:> The val associated w/ the provided status. Can be undef if you 
didn't map the given status to a grade in the C<rubric>.

=cut

method getGradeVal (MyTester::TestStatus $testStatus) {
   return $self->getGrade($testStatus)->val();
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################


1;