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
use Modern::Perl '2012';
use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use Data::Dumper;
use TryCatch;

use MyTester::Reports::ReportLine;
################################################################################
# Constants
################################################################################

################################################################################
# Attributes
################################################################################

=pod

=head1 Public Attributes

=head2 body

   has 'body' => (
      isa => 'ReportLineList, # ArrayRef subtype
      traits => [qw(Array)],
      is => 'rw',
      default => sub { [] },
      handles => {
         addLines => 'push',
         addBlankLine => [
            push => MyTester::Reports::ReportLine->new(line => "")
         ],
         getLine => 'get',
         getLines => 'elements',
         bodyLineCount,
      }
   );
   
The lines in this report. See L<MyTester::Subtypes/ReportLineList>. 
   
=cut

has 'body' => (
   isa => 'ReportLineList',
   traits => [qw(Array)],
   is => 'rw',
   coerce => 1,
   default => sub { [] },
   handles => {
      addLines => 'push',
      addBlankLine => [
         push => MyTester::Reports::ReportLine->new(line => "")
      ],
      getLine => 'get',
      getLines => 'elements',
      bodyLineCount => 'count',
      _mapLines => 'map',
   }
);

=pod

   has 'header' => (
      isa => 'MyTester::Reports::ReportLine',
      is => 'rw',
      predicate => 'headerSet',
   );
   
If set, will be rendered before C<body>.

=cut

has 'header' => (
   isa => 'MyTester::Reports::ReportLine',
   is => 'rw',
   coerce => 1,
   predicate => 'headerSet',
);

=pod

   has 'footer' => (
      isa => 'MyTester::Reports::ReportLine',
      is => 'rw',
      predicate => 'footerSet',
   );

If set, will be rendered after C<body>.


=cut

has 'footer' => (
   isa => 'MyTester::Reports::ReportLine',
   is => 'rw',
   coerce => 1,
   predicate => 'footerSet',
);

=pod

=head2 columns

   has 'columns' => (
      isa => 'PositiveInt',
      is => 'rw',
      default => 80,
   );

How many columns all L<MyTester::Reports::ReportLine> objects should have when
this report is rendered 

=cut

has 'columns' => (
   isa => 'PositiveInt',
   is => 'rw',
   default => 80,
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
   my @renderedLines = ();
   
   push (@renderedLines, $self->header()) if $self->headerSet();
   push (@renderedLines, $self->getLines());
   push (@renderedLines, $self->footer()) if $self->footer();
   
   return join("\n", map {
      $_->columns($self->columns()); 
      $_->render($indentSize) 
   } @renderedLines);
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################


1;