#!perl

=pod

=head1 Name

MyTester::Roles::GenReport - Role to be consumed by classes who wish to generate
reports.

=head1 Version

No set version right now

=head1 Description

The various attributes behind generating a report (indentation, columns, etc.)
are generic enough to be put in a single module and shared. This role wraps this
into one place to be easily consumed by classes like L<MyTester::TestBatch> &
L<MyTester::TestOven>

=cut

package MyTester::Roles::GenReport;
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
use MyTester::Reports::ReportLine;
use MyTester::Roles::Identifiable;

################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 reportBaseIndent

   has 'reportBaseIndent' => (
      isa => 'PositiveInt',
      is => 'rw',
      default => 0
   );
   
The indentation level to put reports on

=cut

has 'reportBaseIndent' => (
   isa => 'PositiveInt',
   is => 'rw',
   default => 0
);

=pod

=head2 reportColumns

   has 'reportColumns' => (
      isa => 'PositiveInt',
      is => 'rw',
      default => 80,
   );

The number of columns each report line will be wrapped on.

=cut

has 'reportColumns' => (
   isa => 'PositiveInt',
   is => 'rw',
   default => 80,
);

=pod

   has 'reportWithHeader' => (
      isa => 'Bool',
      is => 'rw',
      default => 0,
   );

Whether to include a header for this report.Default 0. If true, will indent all
of this report's lines in an extra level of indentation, putting only the header
at the given indentation level. I.e

=over

   Your header # Indent level N
      Report 1 # Indent level N + 1
      Report 2
      ...
      
=back

=cut

has 'reportWithHeader' => (
   isa => 'Bool',
   is => 'rw',
   default => 0,
);

=pod

   has 'reportWithFooter' => (
      isa => 'Bool',
      is => 'rw',
      default => 0,
   );

Whether this report should be generated w/ a footer or not.

=cut

has 'reportWithFooter' => (
   isa => 'Bool',
   is => 'rw',
   default => 0,
);

=pod

   has 'reportWrapLineRegex' => (
      isa => 'RegexpRef',
      is => 'rw',
      predicate => 'wrapLineRegexDefined',
   );

If provided, will be matched against all L<MyTester::Reports::ReportLine> 
objects to determine how much indentation to give to the parts of the lines 
that wrap past L</reportColumns>. See 
L<MyTester::Reports::ReportLine/computeBrokenLineIndentation>.

=cut

has 'reportWrapLineRegex' => (
   isa => 'RegexpRef',
   is => 'rw',
   predicate => 'wrapLineRegexDefined',
);

################################################################################
# Methods
################################################################################

=pod

=head1 Required Methods

=head2 buildReport

Builds a report.

B<Returns:> L<MyTester::Reports::Report>

=cut

requires qw(buildReport);

=pod

=head1 Public Methods

=head2 buildReportHeader

Generates a header for a report 

B<Parameters>

=over

=item $indent? (L<MyTester::Subtypes/PositiveInt) => Indentation level of 
generated line. Default 0. 

=back

B<Returns:> a L<header|MyTester::Reports::ReportLine> for this report 

=cut

method buildReportHeader (PositiveInt :$indent? = 0) {
   return MyTester::Reports::ReportLine->new(
      indent => $indent,
      line => "Report for '".$self->id()."'");
}

=pod

Not yet implemented

=cut

method buildReportFooter (PositiveInt :$indent? = 0) {
   ...;
   return MyTester::Reports::ReportLine->new(
      indent => $indent,
      line => "End report for '".$self->id()."'");
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

with qw(MyTester::Roles::Identifiable);

1;