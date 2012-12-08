#!perl

=pod

=head1 Name

MyTester::Roles::Dependant - Role to consume when you want your test to be
dependant on the outcome of another test. More specifically, it will be 
dependant on the outcome of a certain L<MyTester::Roles::Provider> consumer.

=head1 Version

No set version right now

=cut

package MyTester::Roles::Dependant;
use 5.010;
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
         addProviders => 'set',
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
      addProviders => 'set',
      getProviders => 'values',
      providerCount => 'count',
   }
);

around 'addProviders' => sub {
   my ($orig, $self, @providers) = @_;
   
   my %providerMap = map { $_->id() => $_ } @providers;
   
   $self->$orig(%providerMap);
};

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