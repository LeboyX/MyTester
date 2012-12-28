#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;

use List::Util qw(sum);

use Test::Exception;
use Test::More;
use Test::Warn;

use TryCatch;

use MyTester::Roles::Identifiable;
use MyTester::Util::IdSet;
################################################################################

package SimpleId {
   use Moose;
   with qw(MyTester::Roles::Identifiable);
}

my %tests = (
   CRUD_test => sub {
      my $set = MyTester::Util::IdSet->new();

      my @ids = ();
      push (@ids, SimpleId->new()) for 1..5;

      $set->addIds(@ids);

      for (@ids){
         my $idStr = $_->id();
         ok($set->hasId($_), "Says it has added id '$idStr'");
         is_deeply($set->getId($_), $_, "Retrieved added id '$idStr'");
      }

      is($set->getId(""), undef, "Got undef for non-existant id");
   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();
