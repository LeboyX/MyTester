#!perl

=pod

=head1 Name

MyTester::Util::IdSet - Simple set to make it easy to store a map of 
L<identifiable|MyTester::Roles::Identifiable> objects into a set-like object.

=head1 Version

No set version right now

=head1 Synopsis

TODO

=cut

package MyTester::Util::IdSet;
use Modern::Perl '2012';
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use Data::Dumper;

use MyTester::Subtypes;
use MyTester::Roles::Identifiable;
################################################################################
# Constants
################################################################################

################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 setMap

   has 'setMap' => (
      isa => 'HashRef[MyTester::Roles::Identifiable]',
      traits => [qw(Hash)],
      is => 'ro',
   );

Map of ids. Keyed on L<id|MyTester::Roles::Identifiable/id>; yields the 
L<identifiable|MyTester::Roles::Identifiable> object

=cut

has 'setMap' => (
   isa => 'HashRef[MyTester::Roles::Identifiable]',
   traits => [qw(Hash)],
   is => 'ro',
   handles => {
      _getId => 'get',
      _addIds => 'set',
      _delIds => 'delete',
      _hasId => 'exists',
   }
);


################################################################################
# Methods
################################################################################

=pod

=head1 Public Mehtods

=head2 getId

Gets the L<object|MyTester::Roles::Identifiable> w/ the given ID.

B<Parameters>

=over

=item * [0] (L<MyTester::Subtypes/"MyTester::QuickId">): id to lookup

=back

B<Returns:> L<identifiable|MyTester::Roles::Identifiable> object contained in 
this set. Can be undef if C<!$self-E<gt>hasId($id)>.

=cut

method getId (MyTester::QuickId $id! does coerce) {
   return $self->_getId($id);
}

=pod

=head2 addIds

Adds the given L<identifiable|MyTester::Roles::Identifiable> objects to this 
set.

B<Parameters>

=over

=item * [0-*] (L<MyTester::Roles::Identifiable>): slurpy array of identifiable
objects to add

=back

B<Returns:> C<$self>

=cut

method addIds (MyTester::Roles::Identifiable @ids!) {
   $self->_addIds(map { $_->id() => $_ } @ids);
   return $self;
}

=pod

=head2 delId

Deletes the given ids from this set.

B<Parameters>

=over

=item * [0-*] (L<MyTester::Subtypes/"MyTester::QuickId">): ids to delete

=back

B<Returns:> C<$self>

=cut

method delIds (MyTester::QuickId @ids! does coerce) {
   $self->_delids(@ids);
   return $self;
}

=pod

=head2 hasId

Returns whether this set has the given id or not

B<Parameters>

=over

=item * [0] (L<MyTester::Subtypes/"MyTester::QuickId">): id for which to check

=back

B<Returns:> true if this set has the id. False otherwise.

=cut

method hasId (MyTester::QuickId $id! does coerce) {
   return $self->_hasId($id);
}

1;
