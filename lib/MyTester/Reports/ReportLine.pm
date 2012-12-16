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
encapsulated a single line in a report (duh). It'll handle things like 
line-wrapping (if you desire). 

=head1 TODO

Support line wrapping and justification on a given 'break'

=cut

package MyTester::Reports::ReportLine;
use 5.010;
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
   );
   
   An indent level to indent this report line. Must be > -1

=cut

has 'indent' => (
   isa => 'PositiveInt',
   is => 'rw',
   default => 0,
);

=pod

=head2 columns

   has 'columns' => (
      isa => 'PositiveInt',
      is => 'rw',
      default => 80,
   );

How many columns a a line from L</render> should have before be wrapped onto a 
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

method render (PositiveInt $indentSize? = 0) {
   local ($Text::Wrap::columns) = $self->columns();
   local ($Text::Wrap::unexpand) = 0;
   
   my $initialTab = " " x ($self->indent() * $indentSize);
   return wrap($initialTab, $self->brokenLineIndentation(), $self->line());
}

method computeBrokenLineIndentation (RegexpRef $delimiter!) {
   $self->line() =~ $delimiter;
   return $self->brokenLineIndentation(" " x ($+[0]));
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################


1;