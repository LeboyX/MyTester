use 5.010;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my @ts = glob("t/*.t");
my $class = Module::Build->subclass(
   class => "MyBuilder",
   code => << 'SUBCLASS' );
   
sub ACTION_readme {
   my $self = shift;
   
   $self->do_system ("podselect lib/MyTester.pm > README.pod");
   $self->do_system ("git add README.pod");
}

SUBCLASS

my $builder = $class->new(
    module_name         => 'MyTester',
    dist_abstract => "Personal module for testing code",
    dist_author         => q{Jason Kilroy <leboyX@gmail.com>},
    dist_version_from   => 'lib/MyTester.pm',
    release_status      => 'stable',
    configure_requires => {
       'Module::Build' => 0,
    },
    build_requires => {
       'Test::Exception' => 0.31,
       'Test::More' => 0,
       'Time::HiRes' => 1.9721,
       'TryCatch' => 1.003000,
    },
    requires => {
       'Carp' => 1.26,
       'IPC::Run' => 0.91,
       'File::Which' => 1.09,
       'Moose' => 2.0604,
       'MooseX::StrictConstructor' => 0.19,
       'MooseX::Method::Signatures' => 0.43,
       'Parallel::ForkManager' => 0.007009,
    },
    add_to_cleanup     => [ 'MyTester-*' ],
    create_makefile_pl => 'traditional',
    tap_harness_args => {
       jobs => 4
    },
    timer => 1,
    show_count => 1,
);

$builder->create_build_script();
