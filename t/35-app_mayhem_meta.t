#!perl

# test the metadata object

package Test::App::Mayhem::Meta;
# test object
use Mouse;
with qw(
    App::Mayhem::Meta
    App::Mayhem::Utils
);

use constant {
    LOGNAME => q(Test),
    API_VERSION => 0,
};

# to keep mouse happy, it doesn't understand this quote syntax
sub qv {

}
package main;
use strict;
use warnings;

#use Test::More tests => 1;
use Test::More qw(no_plan);
use Test::File;

BEGIN {
    use_ok( q(Log::Log4perl), qw(:no_extra_logdie_message));
    use_ok( q(File::Basename)); # used to find log4perl config file
    use_ok( q(App::Mayhem) );
    use_ok( q(App::Mayhem::Meta) );
} # BEGIN

# load resources here, and test for them on the underlying filesystem
my $dirname = dirname($0);
file_exists_ok(qq($dirname/tests.log4perl.cfg),
    q(log4perl config file exists for testing));
Log::Log4perl->init_once(qq($dirname/tests.log4perl.cfg));
my $log = Log::Log4perl->get_logger();
isa_ok($log, q(Log::Log4perl::Logger));

diag( qq(\nTesting App::Mayhem::Meta $App::Mayhem::Meta::VERSION;\n)
    . qq(Perl $], $^X) );

    my $meta = Test::App::Mayhem::Meta->new();
    isa_ok($meta, q(Test::App::Mayhem::Meta));

### CHECK PATH LIST
    $log->debug(q(Test: running ->meta_get_search_paths));
    my @paths = $meta->meta_get_search_paths();
    ok( scalar(@paths) > 0,
        scalar(@paths) . q( paths returned from meta_get_search_paths));
    diag(qq(Paths:\n) . join(qq(\n), @paths));

### CHECK ALL ENGINE MODULES
    $log->debug(q(Test: running ->meta_get_all_engines_list));
    my @all_engines = $meta->meta_get_all_engines_list();
    ok( scalar(@all_engines) > 0,
        scalar(@all_engines)
            . q( engines returned from meta_get_all_engines_list));

### GET NON-RUNNABLE ENGINES
    $log->debug(q(Test: running ->meta_get_nonrunnable_engines_list));
    my @nonrunnable = $meta->meta_get_nonrunnable_engines_list();
    ok( scalar(@nonrunnable) > 0,
        scalar(@nonrunnable) . q( non-runnable engines returned from )
            . q( meta_get_nonrunnable_engines_list));
    foreach my $nonrun ( @nonrunnable) {
        ok($nonrun, qq(non-runnable engine found: $nonrun));
    }

### GET RUNNABLE ENGINE MODULES
    $log->debug(q(Test: running ->meta_get_runnable_engines_list));
    my @engines = $meta->meta_get_runnable_engines_list();
    ok( scalar(@engines) > 0,
        scalar(@engines)
            . q( engines returned from meta_get_runnable_engines_list));
    foreach my $engine_name ( @engines ) {
        ok($engine_name, qq(engine found: $engine_name));
    }

### CHECK THAT NON-RUNNABLE + RUNNABLE = ALL_ENGINES
    $log->debug(q(Test: verifying that non-runnable + runnable )
        . q(= total engines));
    ok(scalar(@nonrunnable) + scalar(@engines) == scalar(@all_engines),
        q|non-runnable (| . scalar(@nonrunnable)
        . q|) + runnable engines (| . scalar(@engines)
        . q|) = total number of engines (| . scalar(@all_engines) . q|)|);

### INSTANTIATE ENGINE OBJECTS
    $log->debug(q(Test: instantiating engine objects));
    foreach my $engine ( @engines ) {
        my $module = $meta->lazy_object($engine);
        ok(ref($module), q(Created new module: ) . ref($module));
    }

### CHECK FILE RESOURCES
    # img_configure_button    => q(configure.16x16.png),
    file_exists_ok($meta->meta_get_resource_path(q(img_configure_button)));
    like($meta->meta_get_resource_path(q(img_configure_button)),
        qr{App/Mayhem/Meta/configure\.16x16\.png$},
        q(validate Configure button file path));

    # file_gtkrc              => q(gtkrc.Nodoka-Fuego),
    file_exists_ok($meta->meta_get_resource_path(q(file_gtkrc)));
    like($meta->meta_get_resource_path(q(file_gtkrc)),
        qr{App/Mayhem/Meta/gtkrc\.Nodoka-Fuego$},
        q(validate Nodoka Fuego gtkrc path));

    # img_logo_300x72         => q(mayhem-logo.neon.orange-300x72.jpg),
    file_exists_ok($meta->meta_get_resource_path(q(img_logo_300x72)));
    like($meta->meta_get_resource_path(q(img_logo_300x72)),
        qr{App/Mayhem/Meta/mayhem-logo\.neon\.orange-300x72\.jpg$},
        q(validate mayhem logo path - neon orange 300x72));

    # img_logo_500x109        => q(mayhem-logo.neon.orange-500x109.jpg),
    file_exists_ok($meta->meta_get_resource_path(q(img_logo_500x109)));
    like($meta->meta_get_resource_path(q(img_logo_500x109)),
        qr{App/Mayhem/Meta/mayhem-logo\.neon\.orange-500x109\.jpg$},
        q(validate mayhem logo path - neon orange 500x109));

    # img_logo_text           => q(mayhem-logo.text.neon.orange-300x75.jpg),
    file_exists_ok($meta->meta_get_resource_path(q(img_logo_text)));
    like($meta->meta_get_resource_path(q(img_logo_text)),
        qr{App/Mayhem/Meta/mayhem-logo\.text\.neon\.orange-300x75\.jpg$},
        q(validate mayhem text logo path - neon orange 300x75));

    # img_left_sidebar        => q(mohawkb-skinny-150x234.jpg),
    file_exists_ok($meta->meta_get_resource_path(q(img_left_sidebar)));
    like($meta->meta_get_resource_path(q(img_left_sidebar)),
        qr{App/Mayhem/Meta/mohawkb-skinny-150x234\.jpg$},
        q(validate mayhem left sidebar image - mohawkb-skinny-150x234));

    # layout_compact          => q(mayhem_compact_layout.glade),
    file_exists_ok($meta->meta_get_resource_path(q(layout_compact)));
    like($meta->meta_get_resource_path(q(layout_compact)),
        qr{App/Mayhem/Meta/mayhem_compact_layout\.glade$},
        q(validate mayhem compact layout glade file));

    # layout_larger           => q(mayhem_larger_layout.glade),
    file_exists_ok($meta->meta_get_resource_path(q(layout_larger)));
    like($meta->meta_get_resource_path(q(layout_larger)),
        qr{App/Mayhem/Meta/mayhem_larger_layout\.glade$},
        q(validate mayhem larger layout glade file));

    # layout_splashscreen     => q(mayhem_splashscreen.glade),
    file_exists_ok($meta->meta_get_resource_path(q(layout_splashscreen)));
    like($meta->meta_get_resource_path(q(layout_splashscreen)),
        qr{App/Mayhem/Meta/mayhem_splashscreen\.glade$},
        q(validate mayhem splashscreen glade file));

# fin!
