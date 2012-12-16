#!perl

=pod

=head1 Name

MyTester::Reports::Report - Represents a grade report of any sort - whether for
a single test or a collection of tests. 

=head1 Version

No set version right now

=head1 Synopsis

   my $report = MyTester::Reports::Report->new();
   my $t = MyTester::Tests::Base->new();
   
   # Do stuff w/ $t
   
   $report->catReport($t->getResolvedReport());


=head1 Description

Wraps up a collection of L<MyTester::Report::ReportLine> objects. You can add
lines to a report individually, or add another, already-generated report to
this one. 

=cut

package MyTester::Reports::Report;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use Data::Dumper;
use TryCatch;

use MyTester::Subtypes;
use MyTester::Reports::ReportLine;
################################################################################
# Constants
################################################################################


################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 lines

   has 'lines' => (
      isa => 'ArrayRef[MyTester::Reports::ReportLine]',
      traits => [qw(Array)],
      is => 'rw',
      default => sub { [] },
      handles => {
         addLines => 'push',
         getLine => 'get',
         getLines => 'elements',
      }
   );
   
   The lines in this report.
   
=cut

has 'lines' => (
   isa => 'ArrayRef[MyTester::Reports::ReportLine]',
   traits => [qw(Array)],
   is => 'rw',
   default => sub { [] },
   handles => {
      addLines => 'push',
      getLine => 'get',
      getLines => 'elements',
      _mapLines => 'map',
   }
);

################################################################################
# Methods
################################################################################

=pod

=head2 catReport

Adds a L<MyTester::Reports::Report> objects lines into this report.

B<Parameters>

=over

=item [0]! (L<MyTester::Reports::Report>): The reports whose lines we'll cat 
into this one

=back

=cut

method catReport (MyTester::Reports::Report $r!) { 
   $self->addLines($r->getLines());
}

=pod

=head2 render

This entire report, w/ each L<MyTester::Reports::ReportLine> object delimited 
w/ a newline ("\n");

B<Parameters>

=over

=item [0]? (L<MyTester::Subtypes/PositiveInt>): The indentation size to be used
for all the L<MyTester::Reports::ReportLine> objects in this report. Default is
3 

=back

B<Returns:> this entire report, w/ each L<MyTester::Reports::ReportLine> object
delimited w/ a newline ("\n"); 

=cut

method render (PositiveInt $indentSize? = 3) {
   return join("\n", $self->_mapLines(sub { $_->render($indentSize) }));
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################


1;