#!perl

=pod

=head1 Name

MyTester::Dir - Simple representation of a directory

=head1 Version

No set version right now

=head1 Synopsis

   my $dir = MyTester::Dir->new(name => "myDir/subDir/");

=head1 Description

While there's always L<IO::Dir>, all this does is wrap a string w/ a little bit
of validation when setting a directory. 

=cut

package MyTester::Dir;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

use Carp;

################################################################################
# Imports
################################################################################

################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 name

   has 'name' => (
      isa => 'Str',
      is => 'rw',
      default => ".",
      trigger => sub {
         my ($self, $val) = @_;
         croak "'$val' is not a valid directory" if !-d $val;
      }
   ); 

Sets what dir we're to represent. Must be a valid, already-existing dir.

=cut

has 'name' => (
   isa => 'Str',
   is => 'rw',
   default => ".",
   trigger => sub {
      #TODO: Create dir if it doesn't already exist
      my ($self, $val) = @_;
      croak "'$val' is not a valid directory" if !-d $val;
   }
);

################################################################################
# Methods
################################################################################

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

1;