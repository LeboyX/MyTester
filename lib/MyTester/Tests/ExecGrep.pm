#!perl

=pod

=head1 Name

MyTester::Tests::ExecGrep - Test to run a command and match its output against
a regular expression

=head1 Version

No set version right now

=head1 Synopsis

   my $t = MyTester::Tests::ExecGrep->new(
      cmd => 'echo',
      regex => "qr/hello/;");
   
   my $strToEcho = "hello world";
   $t->addArg($strToEcho);
   $t->test(); # Will pass

=head1 Description

Takes a command, runs it, and tries to match its output to the supplied regex. 
Will set its status to L<MyTester::TestStatus/PASSED> or 
L<MyTester::TestStatus/FAILED> appropriately.

=cut

package MyTester::Tests::ExecGrep;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;
extends qw(MyTester::SimpleTest);

################################################################################
# Imports
################################################################################
use Carp;
use Data::Dumper;
use TryCatch;

use MyTester::ExecEx;
use MyTester::TestStatus;
################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 regex

   has 'regex' => (
      isa => 'Str',
      is => 'rw',
      required => 1,
      trigger => sub {
         my ($self, $val) = @_;
         
         eval "$val";
         croak "Error: Invalid regex supplied: '$@'" if $@;
      }
   );

As can be seen from its type and trigger, this is designed to be a quoted
qr// expression. Due to limitations in the L<Storable> module, the regex needs 
to be in a form easily serialized. The string you supply will be eval'd to turn
it into a real regex to use for output matching.

=cut

has 'regex' => (
   isa => 'Str',
   is => 'rw',
   required => 1,
   trigger => sub {
      my ($self, $val) = @_;
      
      eval "$val";
      croak "Error: Invalid regex supplied: '$@'" if $@;
   }
);

=pod

=head2 exec

   has 'exec' => (
      isa => 'MyTester::ExecEx',
      is => 'rw',
      required => 1,
      handles => {
         cmd => 'cmd',
         addFlag => 'addFlag',
         addArg => 'addArg',
         out => 'derefOut',
      }
   );

The command to run which'll generate output for us to match on.

=cut

has 'exec' => (
   isa => 'MyTester::ExecEx',
   is => 'rw',
   required => 1,
   handles => {
      cmd => 'cmd',
      addFlag => 'addFlag',
      addArg => 'addArg',
      out => 'derefOut',
   }
);

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 getRegex

B<Returns:> the eval'd version of L</regex>, thus reconstituting into into a
regex ref.

=cut

method getRegex () {
   return eval("return ".$self->regex()."");
}

=pod

=head2 test

Runs the command you supplied. Gives the command a 5 second timeout.

B<Returns:> C<$self>

=cut

method test () {
   my $h = $self->exec()->buildHarness(t => 5);
   $h->pump();
   $h->finish();
   
   return $self;
}

=pod

=head2 afterTest

Compares the output of L</exec> w/ the L</regex> supplied. If it matches, will
set C<testStatus> to L<MyTester::TestStatus/PASSED>. Else, sets it to 
L<MyTester::TestStatus/FAILED>.

=cut

method afterTest () {
   my $regex = $self->getRegex();
   if ($self->exec()->derefOut() =~ $regex) {
      $self->testStatus($MyTester::TestStatus::PASSED);
   }
   else {
      $self->testStatus($MyTester::TestStatus::FAILED);
   }
}

=pod

=head2 handleFailedProviders

Since the very act of calling this method means that some providers failed, will
immediately call L<MyTester::Roles::Testable/fail>
with status L<MyTester::TestStatus/DEPENDENCY_UNSATISFIED>.

=cut

method handleFailedProviders {
   $self->fail($MyTester::TestStatus::DEPENDENCY_UNSATISFIED);
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

=pod

=head1 Roles Consumed

=over

=item * L<MyTester::Roles::Testable>

=item * L<MyTester::Roles::Dependant>

=back

=cut

with qw(MyTester::Roles::Testable MyTester::Roles::Dependant);

1;