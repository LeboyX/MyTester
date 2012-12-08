#!perl
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

has 'providersFailed' => (
   isa => 'Bool',
   is => 'ro',
   default => 0,
   writer => '_providersFailed'
);

################################################################################
# Methods
################################################################################

requires qw(handleFailedProviders);

around 'addProviders' => sub {
   my ($orig, $self, @providers) = @_;
   
   my %providerMap = map { $_->id() => $_ } @providers;
   
   $self->$orig(%providerMap);
};

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

with qw(MyTester::Roles::Identifiable);

1;