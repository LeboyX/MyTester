#!perl

=pod

=head1 Name

MyTester::Roles::Provider - Role to consume when you want your test(s) to have
other tests depend on them

=head1 Version

No set version right now

=head1 Synopsis

   #
   # $provider how now $dependant as a dependant AND $dependant now has 
   # $provider as a provider
   #
   $provider->addDep($dependant);

=head1 Description

This role defines a simple C<provides> method to call to see whether or not 
a consumer does, at the time of calling, provide for its dependents. 

This role and L<MyTester::Roles::Dependant> are closely tied together. Changes
to one object's providers/dependants will effect the other's 
dependants/providers (respectively).

=cut

package MyTester::Roles::Provider;
use Modern::Perl '2012';
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use MyTester::Roles::Dependant;
use MyTester::Roles::Identifiable;
################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 dependants

   has 'dependants' => (
      isa => 'HashRef[MyTester::Roles::Dependant]',
      traits => [qw(Hash)],
      is => 'ro',
      default => sub { {} },
      handles => {
         dependantCount => 'count',
      },
   );

Map of dependants we currently have. Though it's a hash for easy lookups and
to avoid duplicates, L<addDeps|/addDeps> and L<delDeps|/delDeps> let you treat
it like an array

=cut

has 'dependants' => (
   isa => 'HashRef[MyTester::Roles::Dependant]',
   traits => [qw(Hash)],
   is => 'ro',
   default => sub { {} },
   handles => {
      dependantCount => 'count',
      _addDeps => 'set',
      _delDeps => 'delete',
      _hasDep => 'exists',
   },
);

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 addDeps

Adds dependants to this provider. Will not add duplicates.

B<Parameters>

=over

=item [0-*] (L<Dependants|MyTester::Roles::Dependant>): Slurpy array of 
dependants to add to this provider

=back

B<Returns:> C<$self>

=head3 Side effects

This method will call L<MyTester::Roles::Dependants/addProvider> on the effected
deps you passed in. 

=cut

method addDeps (MyTester::Roles::Dependant @deps!) {
   my @toAdd = grep { !$self->hasDep($_) } @deps;
   
   if (@toAdd) {
      $self->_addDeps(map { $_->id() => $_ } @toAdd);
      
      for my $dep (@toAdd) {
         $dep->addProviders($self);
      }
   }
   
   return $self;
}

=pod

=head2 addDeps

Delete dependants from this provider. Will not try to remove things that aren't
there.

B<Parameters>

=over

=item [0-*] (L<Dependants|MyTester::Roles::Dependant>): Slurpy array of 
dependants to delete from this provider

=back

B<Returns:> C<$self>

=head3 Side effects

This method will call L<MyTester::Roles::Dependants/delProvider> on the effected
deps you passed in. 

=cut

method delDeps (MyTester::Roles::Dependant @deps) {
   my @toDel = grep { $self->hasDep($_) } @deps;
   
   if (@toDel) {
      $self->_delDeps(map { $_->id() } @toDel);
      
      for my $dep (@toDel) {
         $dep->delProviders($self);
      }
   }
   return $self;
}

=pod

=head2 hasDep

Returns whether this consumer provides for the given dependant

B<Parameters>

=over

=item [0] (L<MyTester::Roles::Dependant>): Dependant to check on

=back

B<Returns:> whether this consumer provides for the given dependant

=cut

method hasDep (MyTester::Roles::Dependant $dep) {
   return $self->_hasDep($dep->id());
}

=pod 

=head1 Required Methods

=head2 provides

Called to determine whether, at any point in time, this consumer fulfills 
whatever obligations it needs to in order for dependants to be able to run. 

B<Returns>: Boolean of whether this provider...provides...

=cut

requires qw(provides);

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

=pod

=head1 Roles Consumed

=over

=item * MyTester::Roles::Identifiable: To make it easy to find providers for
dependants by mapping them to provider ids

=back

=cut

with qw(MyTester::Roles::Identifiable);

1;