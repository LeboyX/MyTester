#!perl

=pod

=head1 Name

MyTester::Roles::Dependant - Role to consume when you want your test to be
dependant on the outcome of another test. More specifically, it will be 
dependant on the outcome of a certain L<MyTester::Roles::Provider> consumer.

=head1 Version

No set version right now

=head1 Synopsis

   #
   # $provider how now $dependant as a dependant AND $provider now has 
   # $dependant as a provider
   #
   $dependant->addProvider($provider);

=head1 Description

This role and L<MyTester::Roles::Provider> are closely tied together. Changes
to one object's dependants/providers will effect the other's 
providers/dependants (respectively).

=cut

package MyTester::Roles::Dependant;
use Modern::Perl '2012';
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use MyTester::Roles::Identifiable;
use MyTester::Roles::Provider;
################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 providers

   has 'providers' => (
      isa => 'HashRef[MyTester::Roles::Provider]',
      traits => [qw(Hash)],
      is => 'ro',
      default => sub { {} },
      handles => {
         getProviders => 'values',
         providerCount => 'count',
      }
   );

List of the object upon which this dependant depends. Note that, though this
object is a hash, you will add providers to it as if it were a list; 
C<addProviders> is wrapped internally to convert L<MyTester::Roles::Provider>
consumers into the form we need. 

=cut

has 'providers' => (
   isa => 'HashRef[MyTester::Roles::Provider]',
   traits => [qw(Hash)],
   is => 'ro',
   default => sub { {} },
   handles => {
      getProviders => 'values',
      providerCount => 'count',
      _addProviders => 'set',
      _delProviders => 'delete',
      _hasProvider => 'exists',
   }
);

=head2 providersFailed

   has 'providersFailed' => (
      isa => 'Bool',
      is => 'ro',
      default => 0,
   );

Tells us whether this dependant had any providers fail. Is set internally.

=cut

has 'providersFailed' => (
   isa => 'Bool',
   is => 'ro',
   default => 0,
   writer => '_providersFailed'
);

################################################################################
# Methods
################################################################################

=head1 Required Methods

=head2 handleFailedProviders

Called when at least one provider failed. Gives this dependant a chance to 
respond to the failures of its providers

=head3 Parameters

=over

=item * Slurpy @array of L<MyTester::Roles::Provider> objects, all of which 
failed their L<MyTester::Roles::Provider/provides> call.

=back

=cut

requires qw(handleFailedProviders);

=pod

=head2 addProviders

Adds providers to this dependant. Will not add duplicates

B<Parameters>

=over

=item [0-*] (L<Providers|MyTester::Roles::Providers>): slurpy array of providers
to add to this dependant

=back

B<Returns:> C<$self>

=head3 Side effects

This method will call L<MyTester::Roles::Provider/addDeps> in the effected
providers you passed in. 

=cut

method addProviders (MyTester::Roles::Provider @providers!) {
   my @providersToAdd = grep { !$self->hasProvider($_) } @providers;
   
   if (@providersToAdd) {
      $self->_addProviders(map { $_->id() => $_ } @providersToAdd);
      
      for my $provider (@providersToAdd) {
         $provider->addDeps($self);
      }
   }
   
   return $self;
}

=pod

=head2 delProviders

Delete providers from this dependant. Will not try to delete things that aren't
here.

B<Parameters>

=over

=item [0-*] (L<Providers|MyTester::Roles::Providers>): slurpy array of providers
to delete from this dependant

=back

B<Returns:> C<$self>

=head3 Side effects

This method will call L<MyTester::Roles::Provider/delDeps> in the effected
providers you passed in. 

=cut

method delProviders (MyTester::Roles::Provider @providers!) {
   my @providersToDel = grep { $self->hasProvider($_) } @providers;
   
   if (@providersToDel) {
      $self->_delProviders(map { $_->id() => $_ } @providersToDel);
      
      for my $provider (@providersToDel) {
         $provider->delDeps($self);
      }
   }
   
   return $self;
}

=pod

=head2 hasProvider

Returns whether this consumer depends on the given provider

B<Parameters>

=over

=item [0] (L<MyTester::Roles::Provider>): Provider to look for

=back

B<Returns:> whether this consumer depends on the given provider

=cut

method hasProvider (MyTester::Roles::Provider $provider!) {
   return $self->_hasProvider($provider->id());
}

=head1 Public Methods

=head2 evalProivders

Goes through all our providers via C<$self-E<gt>getProviders()> and C<grep>s for
any which fail the L<MyTester::Roles::Provider/provides> call. The ones that do
are then passed to L<MyTester::Roles::Dependant/handleFailedProviders>.

=cut

method evalProviders () {
   my @failures = grep { !$_->provides(); } $self->getProviders();
   if (scalar @failures > 0) {
      $self->_providersFailed(1);
      $self->handleFailedProviders(@failures)
   } 
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

=pod

=head1 Roles Consumed

=over

=item * MyTester::Roles::Identifiable: To make it easy to ID and map dependants.

=back

=cut

with qw(MyTester::Roles::Identifiable);

1;