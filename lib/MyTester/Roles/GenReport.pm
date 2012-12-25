#!perl
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

has 'baseIndent' => (
   isa => 'PositiveInt',
   is => 'rw',
   default => 0
);

has 'columns' => (
   isa => 'PositiveInt',
   is => 'rw',
   default => 80,
);

has 'withHeader' => (
   isa => 'Bool',
   is => 'rw',
   default => 0,
);

has 'withFooter' => (
   isa => 'Bool',
   is => 'rw',
   default => 0,
);

has 'wrapLineRegex' => (
   isa => 'RegexpRef|Undef',
   is => 'rw',
   default => undef,
);

################################################################################
# Methods
################################################################################

requires qw(buildReport);

=pod

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

TODO

=cut

method buildReportFooter (PositiveInt :$indent? = 0) {
   return MyTester::Reports::ReportLine->new(
      indent => $indent,
      line => "End report for '".$self->id()."'");
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################

with qw(MyTester::Roles::Identifiable);

1;