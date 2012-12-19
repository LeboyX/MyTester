#!perl

=pod

=head1 Name

MyTester::ExecEx - Wraps functionality for running commands on the command line.

=head1 Version

No set version right now

=head1 Synopsis

   my $in = "Hello World!";
   
   my $x = MyTester::ExecEx->new(cmd => "cat", in => \$in);
   my $h = $x->buildHarness();
   
   $h->pump();
   $h->finish();

=head1 Description

Lets you build up a command to execute on the command line. It is assumed that
you're running on a Unix-like architecture - no silly Windows terminal.

You can supply timeouts for your command to ensure that execution doesn't take
forever (such as when testing code submissions w/ infinite loops). Furthermore, 
output is captured in memory and not written to disk, in order to prevent 
infinite loops from writing all over your disk. 

See L<IPC::Run/harness> for details on how much of this is accomplished, as this
class relies heavily on that module for its forking needs. 

=cut

package MyTester::ExecEx;
use Modern::Perl '2012';
use Moose;
use IPC::Run::Timer;

use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use MyTester::ExecFlag;
use MyTester::File;

use Carp;

use Data::Dumper;

use IPC::Run qw(harness timeout);

use File::Which;

use TryCatch;

################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 cmd

   # Uses File::Which to validate
   has 'cmd' => (
      isa => 'Str',
      is => 'rw',
      required => 1,
   );
   
The command to run on the command line. 
=cut

has 'cmd' => (
   isa => 'Str',
   is => 'rw',
   required => 1,
);

=head2 flags

   has 'flags' => (
      isa => 'HashRef[MyTester::ExecFlag]',
      traits => [qw(Hash)],
      is => 'ro',
      default => sub { {} },
      handles => {
         addFlag => 'set',
         getFlag => 'get',
         getAllFlags => 'values',
         flagCount => 'count',
         hasFlags => 'count'
      }
   );

Flags (and their args) you wish to pass to L</cmd>. See L<MyTester::ExecFlag>
for details on building a flag. Flags are of the form C<-flag [args]> or
C<--flag [args]>.

Though this attribute is a hash, the add/get methods are wrapped to let you 
treat this like a list. 

=cut  

has 'flags' => (
   isa => 'HashRef[MyTester::ExecFlag]',
   traits => [qw(Hash)],
   is => 'ro',
   default => sub { {} },
   handles => {
      addFlag => 'set',
      getFlag => 'get',
      getAllFlags => 'values',
      flagCount => 'count',
      hasFlags => 'count'
   }
);

around addFlag => sub {
   my ($orig, $self, @flags) = @_;
   
   my %flagMap = map { $_->name() => $_ } @flags;
   
   $self->$orig(%flagMap);
   return $self;
};

around getFlag => sub {
   my ($orig, $self, @flags) = @_;
   
   my @flagNames = map {
      my $r = $_;
      if (ref($_) && $_->isa("MyTester::ExecFlag")) { 
         $r = $_->name()
      }
      $r;
   } @flags;
   
   return $self->$orig(@flagNames);
};

=head2 args

   has 'args' => (
      isa => 'ArrayRef[Str]',
      traits => [qw(Array)],
      is => 'rw',
      default => sub { [] },
      handles => {
         addArg => 'push',
         addArgs => 'push',
         getArgs => 'elements',
         hasArgs => 'count'
      }
   );

Any additional arguments you wish to pass to L</cmd>. These will be added to 
the cmd line after all L</flags>. As strings, args are pretty simple. They'll
be things like files or whatever else your command needs.

=cut

has 'args' => (
   isa => 'ArrayRef[Str]',
   traits => [qw(Array)],
   is => 'rw',
   default => sub { [] },
   handles => {
      addArg => 'push',
      addArgs => 'push',
      getArgs => 'elements',
      hasArgs => 'count'
   }
);

=pod

=head2 in

   has 'in' => (
      isa => 'Ref',
      is => 'rw',
      
      # By default, no redirected input
      default => sub { my $x = undef; return \$x; }
   );

Reference to where this command will get its input. This is different from the
way input redirection is done on the cmd line (via 'E<lt>'). Do not try and 
redirect input like you do on the cmd line - just pass in a reference to a 
string or filehandle that the cmd can read from.  

=cut

has 'in' => (
   isa => 'Ref',
   is => 'rw',
   default => sub { my $x = undef; return \$x; }
);

=pod

=head2 out

   has 'out' => (
      isa => 'ScalarRef[Str]',
      is => 'rw',
      
      # By default, output gets trashed
      default => sub { my $x = ""; return \$x; }
   );

Where you want the command's STDOUT to go. A string-ref to let you control 
where the data finally gets put on disk. This avoids out-of-control processes
writing all over your disk. 

=cut

has 'out' => (
   isa => 'ScalarRef[Str]',
   is => 'rw',
   default => sub { my $x = ""; return \$x; }
);

=pod

=head2 err

   has 'err' => (
      isa => 'ScalarRef[Str]',
      is => 'rw',
      
      # By default, error gets trashed
      default => sub { my $x = ""; return \$x; }
   );
   
Same thing as L</out>, but for STDERR. 

=cut

has 'err' => (
   isa => 'ScalarRef[Str]',
   is => 'rw',
   default => sub { my $x = ""; return \$x; }
);

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 derefOut

B<Returns:> C<$self-E<gt>out()> de-referenced. 

=cut

method derefOut () {
   return ${$self->out()};
}

=pod

=head2 derefErr

B<Returns:> C<$self-E<gt>err()> de-referenced. 

=cut

method derefErr () {
   return ${$self->err()};
}

=head2 buidHarness

Builds the harness to be used for running your desired command.

B<Parameters>

=over

=item * t => Int: Optional. Timeout for the cmd. If the cmd takes longer than 
$t seconds, it will be forcefully killed and throw an exception. 

=back

B<Returns:> A harness as returned from L<IPC::Run/harness> w/ its input, STDOUT,
and STDERR hooked up to this object's IO references. You can start the command
by calling C<start()>, C<pump()>, C<finish()>, etc. on the object returned as
appropriate for your needs.  

=head3 Decorations

Before building the harness, validation is done on L</cmd>. If it cannot be 
found on the system path (via L<File::Which>) or is not executable, 
L</buildHarness> will croak.

=cut

method buildHarness (Int :$t? = 0) {
   my @flags = ();
   if ($self->hasFlags()) {
      @flags = map {
         $_->build();
      } $self->getAllFlags();
   }

   my @cmd = ($self->cmd(), @flags, $self->getArgs());
   my @harnessArgs = (
      \@cmd,
      $self->in(),
      $self->out(),
      $self->err());
   
   if ($t > 0) {
      my $timer = timeout($t);
      push(@harnessArgs, $timer);
   }
   
   return harness(@harnessArgs);
}

before 'buildHarness' => sub {
   my ($self) = @_;
   
   my $cmd = $self->cmd();
   if (!which($cmd) && !-x $cmd) {
      croak "'cmd' cannot be found in filesystem and/or is not executable";
   }
};

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

1;