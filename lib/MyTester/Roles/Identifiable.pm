#!perl

=pod

=head1 Name

MyTester::Roles::Identifiable - Simple class to make it easy to uniquely 
identify classes

=head1 Version

No set version right now

=head1 Synopsis

   package MyTest;
   
   use Moose;
   with qw(MyTester::Roles::Identifiable);
   
   my $t1 = MyTest->new();                # $t1->id() eq '0'
   my $t2 = MyTest->new();                # $t1->id() eq '1'
   my $t3 = MyTest->new(id => 'myOwnId'); # $t3->id() eq 'myOwnId'
   my $t4 = MyTest->new():                # $t4->id() eq '2'

=head1 Description

Provides a single field C<id> and automatically creates unique values for it
upons instantiation of consuming classes. You can, of course, provide your own
id when constructioning objects, but they it's your job to ensure unique ids 
across all your objects.

=cut

package MyTester::Roles::Identifiable;
use Modern::Perl '2012';
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 id

   my $id = 0;
   has 'id' => (
      isa => 'Str', # Might be 'Any' someday, but I see no need currently
      is => 'rw',
      default => sub { return $id++; },
      trigger => sub {
         my ($self, $val) = @_;
         if (length($val) == 0) {
            croak "Testable id cannot be empty string";
         }
      }
   );

The id field for each consuming class.

=head3 trigger

Upon setting, the id will be validated to ensure you haven't given the empty
string as the id. The empty string and C<undef> are the only two disallowed 
values for C<id>

=cut

my $id = 0;
has 'id' => (
   isa => 'Str',
   is => 'rw',
   default => sub { return $id++; },
   trigger => sub {
      my ($self, $val) = @_;
      if (length($val) == 0) {
         croak "Testable id cannot be empty string";
      }
   }
);

################################################################################
# Methods
################################################################################

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################


1;