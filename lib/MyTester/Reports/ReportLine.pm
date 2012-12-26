#!perl

=pod

=head1 Name

MyTester::Reports::ReportLine - Represents a single 'line' in a report. See
L<MyTester::Reports::Report> for more details on what a report is. 

=head1 Version

No set version right now

=head1 Synopsis

   my $report = MyTester::Reports::Report->new();
   $report->addLine(MyTester::Reports::ReportLine->new(
      line => "(10/15): Passed tests but had warnings");

=head1 Description

Wraps up reporting on tests into more than just a simple string. A ReportLine
encapsulates a single line in a report (duh). It'll handle things like 
line-wrapping (if you desire). 

=cut

package MyTester::Reports::ReportLine;
use Modern::Perl '2012';
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use Data::Dumper;
use Text::Wrap qw(wrap);
use TryCatch;

use MyTester::Subtypes;

################################################################################
# Subtypes & Coercions
################################################################################

=pod

=head1 Subtypes & Coercions

B/c of unusual circular dependency problems between L<MyTester::Subtypes> and
this class, coercions and subtypes related to this class are put here, despite
the recommendtation of L<Moose::Manual::BestPractices>. If someone knows how to
overcome subtype circular dependencies, please let me know. 

=cut

use Moose::Util::TypeConstraints;

=pod

=head2 ReportLineStr

   subtype 'ReportLineStr', as 'Str';
   coerce 'MyTester::Reports::ReportLine',
      from 'ReportLineStr',
      via { MyTester::Reports::ReportLine->new($_); };

Added convenience to create L<MyTester::Reports::ReportLine> objects.

=cut

subtype 'ReportLineStr', as 'Str';
coerce 'MyTester::Reports::ReportLine',
   from 'ReportLineStr',
   via { MyTester::Reports::ReportLine->new($_); };

=pod

=head2 ReportLineList

   subtype 'ReportLineList', as 'ArrayRef[MyTester::Reports::ReportLine]';
   subtype 'ReportLineStrList', as 'ArrayRef[ReportLineStr]';
   coerce 'ReportLineList',
      from 'ReportLineStrList',
      via { [ map { MyTester::Reports::ReportLine->new($_) } @{$_} ] };

Wraps the convenience of L</ReportLineStr> into an array, as it's used for 
L<MyTester::Reports::Report/body>

=cut

subtype 'ReportLineList', as 'ArrayRef[MyTester::Reports::ReportLine]';
subtype 'ReportLineStrList', as 'ArrayRef[ReportLineStr]';
coerce 'ReportLineList',
   from 'ReportLineStrList',
   via { [ map { MyTester::Reports::ReportLine->new($_) } @{$_} ] };


################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 line

   has 'line' => (
      isa => 'Str',
      is => 'rw',
   );
   
   What this line will actually display.
   
=cut

has 'line' => (
   isa => 'Str',
   is => 'rw',
);

=head2 indent

   has 'indent' => (
      isa => 'PositiveInt',
      is => 'rw',
      default => 0,
      handles => {
         incrementIndent => [
            add => 1
         ],
      },
   );
   
   An indent level to indent this report line. Must be > -1

=cut

has 'indent' => (
   isa => 'PositiveInt',
   is => 'rw',
   default => 0,
   handles => {
      incrementIndent => [
         add => 1
      ],
   },
);

=pod

=head2 columns

   has 'columns' => (
      isa => 'PositiveInt',
      is => 'rw',
      default => 80,
   );

How many columns a line from L</render> should have before be wrapped onto a 
new line.

=cut

has 'columns' => (
   isa => 'PositiveInt',
   is => 'rw',
   default => 80,
);

=pod

   has 'brokenLineIndentation' => (
      isa => 'Str',
      is => 'rw',
      default => "",
   );

For lines broken after L</columns> columns, indentation (if any) to prefix onto
the subsequently broken lines. 

=cut

has 'brokenLineIndentation' => (
   isa => 'Str',
   is => 'rw',
   default => "",
);

################################################################################
# Construction
################################################################################

=pod

=head1 Construction

ReportLine supports a non-hash constructor if you pass in 1 parameters. Like so:

   MyTester::Reports::ReportLine->new("MyLine");

This is equivalent to:
   
   MyTester::Reports::ReportLine->new(line => "My Line");

This is used for convenience in L<MyTester::Subtypes/ReportLineStr> to make it
easier to create ad-hoc report lines from just a Str.

=cut

around BUILDARGS => sub {
   my ($orig, $class, @args) = @_;
   
   if ((scalar @args == 1) && (!ref $args[0])) {
      return $class->$orig(line => $args[0]);
   }
   else {
      return $class->$orig(@args);
   }
};

################################################################################
# Methods
################################################################################

=pod

=head1 Public Methods

=head2 render

Renders this line into a Str. Will wrap the string at L</columns> columns (on
qr/\s/) and indent subsequently broken lines w/ whatever is supplied to 
L</brokenLineIndentation>. 

B<Parameters>

=over

=item [0]? (L<MyTester::Subtypes::PositiveInt>): The indentation size to use 
for indenting. Thus, for whatever C<indent> level you gave this line, it will
have C<indent * indentSize> spaces (" ") prepended to the returned string

=back

B<Returns:> this line in Str form, formatted and broken up appropriately.

=cut

method render (Int $indentSize? = 0) {
   local ($Text::Wrap::columns) = $self->columns();
   local ($Text::Wrap::unexpand) = 0;
   
   my $initialTab = " " x ($self->indent() * $indentSize);
   return wrap($initialTab, $self->brokenLineIndentation(), $self->line());
}

=pod

=head2 computeBrokenLineIndentation

Given a regex to match on, will compute how much to indent by indenting broken
lines to line up w/ the end of the first match we get for C<$delimieter>. Sets
L</brokenLineIndentation> to this value.

B<Parameters>

=over

=item [0]!: Regex we'll use to compute how to indent broken lines

=item [1]? (L<MyTester::Subtypes/PositiveInt>): The size of an indent. Default is
3 (spaces)

=back

=cut

method computeBrokenLineIndentation (
      RegexpRef $rx!, 
      PositiveInt $indentSize? = 3) {
   $self->line() =~ $rx;
   
   my $amt = $+[0];
   my $cols = $self->columns();
   if ($amt > $cols) {
      croak "Computed indentation '$amt' cannot be > column max '$cols'";
   }
   
   my $totalBuffer = ($amt + ($self->indent() * $indentSize));
   return $self->brokenLineIndentation(" " x $totalBuffer);
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

1;
