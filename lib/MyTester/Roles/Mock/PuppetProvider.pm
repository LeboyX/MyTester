#!perl

=pod

=head1 Name

MyTester::Roles::Mock::PuppetProvider - Simple consumer of the 
L<MyTester::Roles::Provider> and L<MyTester::Roles::Testable> role. 

=head1 Extends

MyTester::Roles::Mock::EmptyTest - for convenience, as this class consumes the
L<MyTester::Roles::Testable> role.

=head1 Version

No set version right now

=head1 Description

Useful for testing L<MyTester::TestOven>, as tests combined w/ dependency 
important for testing.

Provides basic methods to allow you to determine whether this provider actually
fulfills its dependency after running the L<MyTester::Roles::Testable/test> 
method.

=head1 Special Notes

=over

=item * C<test()> will set this instance up to fullfill/!fullfill its dependency
to whatever you set L<flagForDependants> to.

=back

=cut

package MyTester::Roles::Mock::PuppetProvider;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

extends qw(MyTester::Roles::Mock::EmptyTest);
################################################################################
# Imports
################################################################################
use Carp;
use Data::Dumper;
use TryCatch;

################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 flagForDependants

   has 'flagForDependants' => (
      isa => 'Bool',
      traits => [qw(Bool)],
      is => 'rw',
      default => 0,
      handles => {
         provide => 'set',
         doNotProvide => 'unset',
      }
   );
   
Set this to true if you want this provider to provide appropriatley. Set it 
false if you want it to fail its dependency check

=cut

has 'flagForDependants' => (
   isa => 'Bool',
   traits => [qw(Bool)],
   is => 'rw',
   default => 0,
   handles => {
      provide => 'set',
      doNotProvide => 'unset',
   }
);

has '_toProvide' => (
   isa => 'Bool',
   is => 'rw',
);

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 test

Sets the value we'll return from L<provides> to C<flagForDependants>

=cut

method test { 
   $self->_toProvide($self->flagForDependants);
}

=pod

=head2 provides

To be called after C<test>: will return whatever you set C<flagForDependants> 
to.

=cut

method provides () {
   return $self->_toProvide();
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

=pod

=head1 Roles Consumed

=over

=item * MyTester::Roles::Provider

=item * MyTester::Roles::Testable

=back

=cut

with qw(MyTester::Roles::Provider MyTester::Roles::Testable);

1;