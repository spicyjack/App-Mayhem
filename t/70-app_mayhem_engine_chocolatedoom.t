#!perl -T

#use Test::More tests => 3;
use Test::File;
use Test::More q(no_plan);
use Test::Mouse;

BEGIN {
    use_ok( q(Log::Log4perl), qw(:no_extra_logdie_message));
    use_ok( q(File::Basename)); # used to find log4perl config file
    use_ok( q(App::Mayhem) );
    use_ok( q(App::Mayhem::Engine::ChocolateDoom) );
} # BEGIN

    diag( qq(Testing App::Mayhem::Engine::ChocolateDoom )
        . qq($App::Mayhem::Engine::ChocolateDoom::VERSION,\n)
        . qq(Perl $], $^X) );

    # set up Log4perl
    my $dirname = dirname($0);
    file_exists_ok(qq($dirname/tests.log4perl.cfg),
        q(log4perl config file exists for testing));
    Log::Log4perl->init_once(qq($dirname/tests.log4perl.cfg));
    my $log = Log::Log4perl->get_logger();
    isa_ok($log, q(Log::Log4perl::Logger));

    # start testing the module
    my $engine = App::Mayhem::Engine::ChocolateDoom->new();

    if ( $engine->is_available() ) {
        diag(q(ChocolateDoom binary available at: ) . $engine->binary_path());
    } else {
        diag(qq(ChocolateDoom engine not installed));
    } # if ( $engine->is_available() )

    ### METACLASS AVAILABILITY ###
    meta_ok($engine);

    ### ATTRIBUTE AVAILABILITY ###
    # alt_deathmatch
    # has_attribute_ok comes from Test::Mouse
    has_attribute_ok( q(App::Mayhem::Engine::ChocolateDoom), q(altdeath),
        qq('altdeath' attribute exists));
    is( $engine->altdeath(), 0, qq(altdeath attribute defaults to 0));

    # config
    has_attribute_ok( q(App::Mayhem::Engine::ChocolateDoom), q(config),
        qq('config' attribute exists));
    is( $engine->config(), undef, qq(config attribute defaults as undefined));

    ### CHECK FOR CONSUMED ROLES ###
    does_ok( $engine, q(App::Mayhem::Game::Doom),
        qq(test object consumed the App::Mayhem::Game::Doom role));
    does_ok( $engine, q(App::Mayhem::Engine::VanillaDoom),
        qq(test object consumed the App::Mayhem::Engine::VanillaDoom role));

    ### CHECK REQUIRED ATTRIBUTES ###
    is( $engine->engine_name(), q(Chocolate Doom),
        q(object provides engine_name attribute));
    ok( length($engine->engine_description()) > 100,
        q(object returned an engine_description attribute; )
        . q(length: ) . length($engine->engine_description()) . q( bytes));
    like( $engine->engine_homepage_uri(), qr{^http://},
        q(object returned an engine_homepage_uri, and may be a valid URI));
    my @engines = $engine->engine_provides();
    ok( scalar( @engines ) > 0,
        q(object provides one or more engines));

    ### SETTING/GETTING VALID ATTRIBUTES ###
    # set some config options...
    ok($engine->config(q(/path/to/some/file)),
        q(set attribute 'config' to /path/to/some/file));
    ok($engine->altdeath(1), q(set attribute 'altdeath' = 1));

TODO: {
    local $TODO = q(add get_commandline_args function);
    # then test for them, command-line style
    # extra whitespace at the end please :)

=pod

    is( $engine->get_commandline_args(qw(config altdeath)),
        q(-altdeath -config /path/to/some/file ),
        qq(test Doom command line; doom.exe )
        . substr($engine->get_commandline_args(), 0, 30) . qq(...)
    ); # is( $engine->get_commandline_args(qw(config altdeath))

    # config-file style
    is( $engine->get_configfile_args(qw(config altdeath)),
        qq([Chocolate Doom]\naltdeath = 1\nconfig = /path/to/some/file\n),
        qq(test Doom config file;\n)
        . $engine->get_configfile_args(qw(config altdeath))
    ); # is( $engine->get_configfile_args(qw(config altdeath))

    ### INVALID ATTRIBUTES ###
    # pass in an invalid list of attributes to return values for, then test
    # that the methods barf correctly
    is( $engine->get_commandline_args(qw(foo bar)),
        undef,
        q(get_commandline_args with bogus attribute names returns 'undef')
    ); # is($engine->get_commandline_args(qw(foo bar)
    is( $engine->get_configfile_args(qw(foo bar)),
        qq([Chocolate Doom]\n),
        q(get_configfile_args w/bogus attribute names returns only header)
    ); # is($engine->get_configfile_args(qw(foo bar))

    ### VALID/INVALID ATTRIBUTES ###
    is( $engine->get_commandline_args(qw(foo config)),
        q(-config /path/to/some/file ),
        q|get_commandline_args (bogus/non-bogus) returns only valid attribute|
    ); # is($engine->get_commandline_args(qw(foo bar)
    is( $engine->get_configfile_args(qw(foo altdeath)),
        qq([Chocolate Doom]\naltdeath = 1\n),
        q(get_configfile_args with bogus/non-bogus returns only valid attribute)
    ); # is($engine->get_configfile_args(qw(foo bar))

    ### DEFAULT CONFIG FILE ###
    # test the docs
    ok(length($engine->get_default_config()) > 2000,
        qq(get_default_config returns data; current length: )
        . length($engine->get_default_config()) . q( bytes) );

=cut

} # TODO
# fin!
