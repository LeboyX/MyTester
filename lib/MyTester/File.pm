#!/usr/bin/perl
package MyTester::File;
use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;
use autodie qw(open);

use Carp;

has 'name' => (
   isa => 'Str',
   is => 'rw',
   required => 1,
   trigger => sub {
      my ($self, $file) = @_;
      croak "'$file' is not a valid file" if !-f $file;
   }
);

method getInputFileHandle () {
   open (my $fh, $self->name());
   return $fh;
}

1;
