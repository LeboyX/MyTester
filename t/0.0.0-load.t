#!/usr/bin/perl 
use Modern::Perl '2012';
use Test::More;
use MyTester;
use File::Find qw(find);

my @modules = ();
find(sub {
   my $name = $File::Find::name;
   if ($name =~ s/\.pm$//) {
      $name =~ s/^.*(MyTester.*)/$1/;
      $name =~ s/\//::/g;
      push (@modules, $name);
   }
}, "lib/");

plan tests => (scalar @modules);
for (@modules) {
   use_ok($_) || print "Bail out!\n";
}
