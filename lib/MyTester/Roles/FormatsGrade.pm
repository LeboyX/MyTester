#!perl
package MyTester::Roles::FormatsGrade;
use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

################################################################################
# Imports
################################################################################
use Carp;
use TryCatch;

use MyTester::Grade;
use MyTester::TestStatus;
################################################################################
# Attributes
################################################################################

has 'maxGrade' => (
   isa => 'MyTester::Grade',
   is => 'rw',
   predicate => 'hasMaxGrade',
   handles => {
      _maxVal => 'val'
   }
);

################################################################################
# Methods
################################################################################

method formatGradeToStr (MyTester::Grade $grade!) returns (Str) {
   my ($val) = ($grade->val());
   
   my $scoreStr = "($val";
   if ($self->hasMaxGrade()) {
      $scoreStr .= $self->_maxVal();
   }
   $scoreStr.= "): ";
   
   $scoreStr .= inner();
   
   return $scoreStr;
}

################################################################################
# Roles (put here to compile properly w/ Moose)
################################################################################


1;