use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Steemit::WsClient',
    license             => 'artistic_2',
    dist_author         => q{snkoehn <koehn.sebastian@gmail.com>},
    dist_version_from   => 'lib/Steemit/WsClient.pm',
    release_status      => 'testing',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
        'Modern::Perl'     => '0',
        'Mojo::Base'       => '0',
        'IO::Socket::SSL'  => '0',
    },
    add_to_cleanup     => [ 'Steemit-*' ],
);

$builder->create_build_script();
