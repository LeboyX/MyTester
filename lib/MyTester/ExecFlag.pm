#!perl

=pod

=head1 Name

MyTester::ExecFlag - Wrapper of a flag passed to L<MyTester::ExecEx>

=head1 Version

No set version right now

=head1 Synopsis

   my $in = "Hello World!";
   
   my $x = MyTester::ExecEx->new(cmd => "cat", in => \$in);
   $x->addFlag(MyTester::ExecFlag->new(name => 't')); # Show tabs
   $x->addFLag(MyTester::ExecFlag->new(name => 'show-ends', isLong => 1);

=head1 Description

Used to add info needed by L<MyTester::ExecEx> to flags you want to pass down to
the command line.

=cut

package MyTester::ExecFlag;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 name

   has 'name' => (
      isa => 'Str',
      required => 1,
      is => 'rw'
   );

Name of the flag as it appears after the "-" on the command line. In other 
words, what your command expects the flag's name to be. 
 
=cut

has 'name' => (
   isa => 'Str',
   required => 1,
   is => 'rw'
);

=pod

=head2 args

   has 'args' => (
      isa => 'ArrayRef[Str]',
      traits => [qw(Array)],
      is => 'ro',
      default => sub { [] },
      handles => {
         addArg => 'push',
         getArgs => 'elements',
         hasArgs => 'count',
      }
   );

Any args to pass to your flag. Will be put on the cmd line as "-flag arg1 arg2".

=cut

has 'args' => (
   isa => 'ArrayRef[Str]',
   traits => [qw(Array)],
   is => 'ro',
   default => sub { [] },
   handles => {
      addArg => 'push',
      getArgs => 'elements',
      hasArgs => 'count',
   }
);

=pod

=head2 isLong

   has 'isLong' => (
      isa => 'Bool',
      is => 'rw',
      default => 0
   );

Whether this flag is long ("--") or not ("-");

=cut

has 'isLong' => (
   isa => 'Bool',
   is => 'rw',
   default => 0
);

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 build

B<Returns:> A string representation of the flag. If C<$self-E<gt>isLong()> 
is false, flag is of the form "-flag arg1 arg2". If true, it'll look like
"--flag arg1 arg2"

=cut 

method build () {
   my $flag = "-";
   if ($self->isLong()) {
      $flag .= "-";
   }
   $flag .= $self->name();
   
   if ($self->hasArgs()) {   
      return ($flag, join(" ", $self->getArgs()));;
   }
   else {
      return $flag;
   }
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

1;