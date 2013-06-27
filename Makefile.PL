use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Mayhem',
    AUTHOR              => 'Brian Manning <brian at xaoc dot com>',
    VERSION_FROM        => 'lib/App/Mayhem.pm',
    ABSTRACT_FROM       => 'lib/App/Mayhem.pm',
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Devel::PPPort'         => 3.19,
        'ExtUtils::MakeMaker'   => 6.42,
        'ExtUtils::ParseXS'     => 2.21,
        'Test::More'            => 0,
        'Test::File'            => 0,
    },
    PREREQ_PM => {
        'perl'                  => 5.006002,
        'Cwd'                   => 0,
        'File::Find::Rule'      => 0,
        'Getopt::Long'          => 0,
        'Glib'                  => 0,
        'Gtk2'                  => 0,
        'IO::Socket::INET'      => 0,
        'Log::Log4perl'         => 0,
        'Mouse'                 => 0,
        'POSIX'                 => 0,
        'threads'               => 0,
        'Time::HiRes'           => 0,
        'version'               => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Mayhem-*' },
);
