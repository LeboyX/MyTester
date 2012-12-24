#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More;

use TryCatch;

use MyTester::Roles::Mock::PuppetProvider;
use MyTester::Roles::Mock::SimpleDependant;
################################################################################

my %tests = (
   addProviderDelProvider_test => sub {
      my $dependant = MyTester::Roles::Mock::SimpleDependant->new();
      my $provider = MyTester::Roles::Mock::PuppetProvider->new();
      
      $dependant->addProviders($provider);
      is($dependant->providerCount, 1, "Dependant has 1 provider");
      is($provider->dependantCount, 1, "Provider has 1 dependant");
      
      $dependant->addProviders($provider);
      is($dependant->providerCount, 1, "Dependant still has 1 provider");
      is($provider->dependantCount, 1, "Provider still has 1 dependant");
      
      $dependant->delProviders($provider);
      is($dependant->providerCount, 0, "Dependant has 0 providers");
      is($provider->dependantCount, 0, "Provider has 0 dependants");
      
      $dependant->delProviders($provider);
      is($dependant->providerCount, 0, "Dependant still has 0 providers");
      is($provider->dependantCount, 0, "Provider still has 0 dependants");
   },
   
   addDependantDelDependant_test => sub {
      my $dependant = MyTester::Roles::Mock::SimpleDependant->new();
      my $provider = MyTester::Roles::Mock::PuppetProvider->new();
      
      $provider->addDeps($dependant);
      is($provider->dependantCount, 1, "Provider has 1 dependant");
      is($dependant->providerCount, 1, "Dependant has 1 provider");
      
      $provider->addDeps($dependant);
      is($provider->dependantCount, 1, "Provider still has 1 dependant");
      is($dependant->providerCount, 1, "Dependant still has 1 provider");
      
      $provider->delDeps($dependant);
      is($provider->dependantCount, 0, "Provider has 0 dependants");
      is($dependant->providerCount, 0, "Dependant has 0 providers");
      
      $provider->delDeps($dependant);
      is($provider->dependantCount, 0, "Provider still has 0 dependants");
      is($dependant->providerCount, 0, "Dependant still has 0 providers");

   },
);

while (my ($testName, $testCode) = each(%tests)) {
   note($testName);
   subtest $testName => $testCode;
}

done_testing();