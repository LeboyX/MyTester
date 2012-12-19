#!/usr/bin/perl

=pod

=head1 Name

MyTester::File - Simple representation of a file

=head1 Version

No set version right now

=head1 Synopsis

   my $dir = MyTester::File->new(name => "myDir/subDir/file");

=head1 Description

While there's always L<IO::File>, all this does is wrap a string w/ a little bit
of validation when setting a file. 

=cut

package MyTester::File;
use Modern::Perl '2012';
use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;
use autodie qw(open);

use Carp;


=pod

=head1 Public Attributes

=head2 name

   has 'name' => (
      isa => 'Str',
      is => 'rw',
      required => 1,
      trigger => sub {
      my ($self, $file) = @_;
      croak "'$file' is not a valid file" if !-f $file;
      }
   ); 

Sets what file we're to represent. Must be a valid, already-existing file

=cut

has 'name' => (
   isa => 'Str',
   is => 'rw',
   required => 1,
   trigger => sub {
      my ($self, $file) = @_;
      croak "'$file' is not a valid file" if !-f $file;
   }
);

=pod

=head1 Public Methods

=head2 getInputFileHandle

B<Returns:> A fresh filehandle pointing at <$self-E<gt>name()>.

=cut

method getInputFileHandle () {
   open (my $fh, $self->name());
   return $fh;
}

1;
