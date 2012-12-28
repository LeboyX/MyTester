#!perl

=pod

=head1 Name

MyTester::Roles::TrackScores - Simple role to encapulsate tracking scores

=head1 Version

No set version right now

=head1 Synopsis

   package SimpleTracker {
      use Moose;
      with qw(MyTester::Roles::TrackScores);
   }
   
   my $t = SimpleTracker->new();
   $t->addScore("score1", 10); # $t->earned() == 10
   $t->addScore("score2", 5);  # $t->earned() == 15;
   $t->addScore("score3", -5); # $t->earned() == 10;
   $t->addScore("score1", 5);  # $t->earned() == 5;

=head1 Description

Useful mostly for L<MyTester::TestBatch> and L<MyTester::TestOven>, but it's
pretty generic.

=cut

package MyTester::Roles::TrackScores;
use 5.010;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use MyTester::Subtypes;
use MyTester::Roles::Identifiable;
################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 scores

   has 'scores' => (
      isa => 'HashRef[Num]',
      traits => [qw(Hash)],
      is => 'ro',
      default => sub { {} },
      handles => {
         getScore => 'get',
         getScores => 'values',
         hasScore => 'exists',
      },
   );

Map of ids to scores earned

=cut

has 'scores' => (
   isa => 'HashRef[Num]',
   traits => [qw(Hash)],
   is => 'ro',
   default => sub { {} },
   handles => {
      getScore => 'get',
      getScores => 'values',
      hasScore => 'exists',
      _setScore => 'set',
   },
);

=pod

=head2 earned

   has 'earned' => (
      isa => 'Num',
      traits => [qw(Number)],
      is => 'ro',
      writer => '_earned',
      default => 0,
      handles => {
         _addScore => 'add',
      }
   );

The total 'earned' of all scores. Same as summing all the values in L</scores>.

=cut

has 'earned' => (
   isa => 'Num',
   traits => [qw(Number)],
   is => 'ro',
   writer => '_earned',
   default => 0,
   handles => {
      _addScore => 'add',
   }
);

=pod

   has 'max' => (
      isa => 'Num',
      is => 'rw',
      trigger => sub {
         my ($self, $val) = @_;
         
         my $earned = $self->earned();
         croak "Max ($val) cannot be less than current sum ($earned)"
            if $val < $earned;
      },
      predicate => 'maxValid',
      clearer => 'clearMax',
   );

The maximum possible score. Must always be higher than L</earned>.

=cut

has 'max' => (
   isa => 'Num',
   is => 'rw',
   trigger => sub {
      my ($self, $val) = @_;
      
      my $earned = $self->earned();
      croak "Max ($val) cannot be less than current sum ($earned)"
         if $val < $earned;
   },
   predicate => 'maxValid',
   clearer => 'clearMax',
);

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 addScore

B<Parameters>

=over

=item * [0]! (L<MyTester::Subtypes/"MyTester::QuickId">): Id to map score to

=item * [1]! (Num): Score to give

=back

B<Returns:> C<$self>

=cut

method addScore(MyTester::QuickId $id! does coerce, Num $score!) {
   my $toAdd = $score;
   if ($self->hasScore($id)) {
      my $curScore = $self->getScore($id);
      
      my $net = $curScore - $score;
      $toAdd = ($curScore > $score) 
         ? $net
         : -$net;
      $toAdd = ($score - $self->getScore($id));
   }
   
   $self->_setScore($id => $score);
   $self->_addScore($toAdd);
   
   return $self;
}

=pod

=head3 Decorations

If adding this score will put L</earned> over L</max>, will carp and set L</max>
to the current value of L</earned>.

=cut

after 'addScore' => sub {
   my ($self) = @_;
   
   if ($self->maxValid()) {
      my $earned = $self->earned();
      my $max = $self->max();
      
      if ($max < $earned) {
         carp "Warning: Earned ($earned) > Max ($max); Max set to '$earned'";
         $self->max($earned);
      } 
   }
};

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################


1;