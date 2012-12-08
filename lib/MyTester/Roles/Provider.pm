#!perl

=pod

=head1 Name

MyTester::Roles::Provider - Role to consume when you want your test(s) to have
other tests depend on them

=head1 Version

No set version right now

=head1 Description

This role defines a simple C<provides> method to call to see whether or not 
a consumer does, at the time of calling, provide for its dependents. 

=cut

package MyTester::Roles::Provider;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use MyTester::Roles::Identifiable;
################################################################################
# Attributes
################################################################################

################################################################################
# Methods
################################################################################

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