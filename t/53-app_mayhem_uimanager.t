#!perl -T

# test modules
#use Test::More tests => 1;
use strict;
use warnings;
use lib q(.); # picks up the directory that contains MayhemTest

use Test::More qw(no_plan);
use Test::File;

use constant {
    LOGNAME => q(Test),
    API_VERSION => 0,
};

diag( qq(\nTesting App::Mayhem::UIManager )
    . qq($App::Mayhem::UIManager::VERSION,\n)
    . qq(Perl $], $^X\n)
    . qq(I am thread #) . threads->tid() . qq(\n)
); # diag

## TEST
BEGIN {

    use_ok(q(Glib));
    use_ok(q(threads));
    use_ok(q(IO::Socket::INET));
    use_ok(q(Log::Log4perl), qw(:no_extra_logdie_message));
    use_ok(q(File::Basename)); # used to find log4perl config file
    use_ok(q(MayhemTest)); # a set of libraries for testing mayhem
    require_ok( 'App::Mayhem::View::SplashScreen' );
} # BEGIN

my $dirname = dirname($0);

## TEST
file_exists_ok(qq($dirname/tests.log4perl.cfg),
    q(log4perl config file exists for testing));
Log::Log4perl->init_once(qq($dirname/tests.log4perl.cfg));
my $log = Log::Log4perl->get_logger();
isa_ok($log, q(Log::Log4perl::Logger));
my $mt = MayhemTest->new();
isa_ok($mt, q(MayhemTest));



### TEST GUTS ###
    # some sample engines to test with
    my @engines = (
        #q(ReMooD),
        #q(Vavoom),
        q(ZDoom),
    ); # my @engines

    # set up the "controller" port
    my $server_port = 8378;
    my $server_address = q(127.0.0.1);

    my $server = IO::Socket::INET->new(
        Listen      => 5,
        Timeout     => 500,
        Proto       => q(tcp),
        LocalPort   => $server_port,
        LocalAddr   => $server_address,
        ReuseAddr   => 1,
    ); # my $server = IO::Socket::INET->new

    my $test_thread = threads->create(
        sub {
            import App::Mayhem::View::SplashScreen;
            App::Mayhem::View::SplashScreen->new(
                server_address  => $server_address,
                server_port     => $server_port
            );
        } # sub
    ); # my $worker_thread = threads->create
    $test_thread->detach();

    ## TEST
    ok($test_thread->is_detached(), q(SplashScreen thread is detached));

    # enter the testing loop
    while (1) {
        my $client;
        $log->debug(LOGNAME . qq(: Parent PID is $$: calling server->accept\n));
        while ( $client = $server->accept() ) {
            $log->debug(LOGNAME
                . qq(: accepted connection: )
                . $client->peerhost()
                . q(, )
                . $client->peerport()
                . qq(\n)
            ); # $log->debug
            $client->autoflush(1);
            ## TEST
            isa_ok($client, q(IO::Socket::INET));

            ## init message from client
            $log->debug(LOGNAME . qq|: reading from client socket (HELLO)|);
            my $init_message = $mt->read_socket($client);
            ## TEST
            my ($command, $remote_name, $api_ver_string, $remote_api_ver)
                                        = split(/ /, $init_message);
            ok($init_message =~ /HELLO Splash api_version \d+/,
                qq(Splash sent hello message: '$init_message'));
            ok($remote_api_ver ge API_VERSION, qq(API Version from socket )
                . qq('$remote_api_ver' is greater than )
                . q(or equal to test API version: ') . API_VERSION . q('));

            $log->debug(LOGNAME
                . qq(: replying to the HELLO message with 'HI'...));
            # ACK the HELLO
            $mt->write_socket(
                socket  => $client,
                message => qq(HI $remote_name Test)
            );

            $log->debug(LOGNAME
                . qq|: reading from client socket (get max progress)|);
            my $max_progress_request = $mt->read_socket($client);
            ## TEST
            ok($max_progress_request eq q(get_max_progress_value),
                qq(received 'get_max_progress_value' message: )
                . qq('$max_progress_request'));

            $log->debug(LOGNAME . qq(: sending 'OK get_max_progress_value'));
            $mt->write_socket(
                socket  => $client,
                message =>q(OK get_max_progress_value),
                sleep   => 1,
            );

            $log->debug(LOGNAME . qq|: sending ping message|);
            $mt->write_socket(
                socket  => $client,
                message => qq(ping)
            );

            $log->debug(LOGNAME
                . qq|: reading from client socket (ping ack)|);
            my $ack = $mt->read_socket($client);
            ## TEST
            ok($ack eq q(OK ping), LOGNAME
                . qq(: splash ack'ed ping with '$ack') );

            $log->debug(LOGNAME
                . qq|: reading from client socket (pong ack)|);
            my $ping_reply = $mt->read_socket($client);
            ## TEST
            ok($ping_reply eq q(pong), LOGNAME
                . qq(: splash replied to ping with '$ping_reply') );

            # counter for how many times we have bumped progress
            $log->debug(LOGNAME . qq(: sending set_max_progress_value: )
                . scalar(@engines) );
            $mt->write_socket(
                socket  => $client,
                message => q(set_max_progress_value ) . scalar(@engines)
            );

            $log->debug(LOGNAME
                . qq|: reading from client socket (set max progress)|);
            $ack = $mt->read_socket($client);
            ## TEST
            ok($ack eq q(OK set_max_progress_value),
                qq(splashscreen ack'ed set_max_progress_value: $ack));

            $log->debug(LOGNAME
                . qq|: reading from client socket (init all engines)|);
            my $init = $mt->read_socket($client);
            ## TEST
            ### FIXME this breaks sometimes, may need some delay?
            #ok($ack eq q(init_all_engines),
            ok($init eq q(init_all_engines),
                qq(splashscreen initialization of engine modules: $init));
            $log->debug(LOGNAME
                . qq(: replying to init_all_engines with OK));
            $mt->write_socket(
                socket  => $client,
                message => q(OK init_all_engines),
                sleep   => 1,
            );

            my $loops = 1;

            # save the last message received from the other end of the socket
            # so we can test for it when it (below) gets sent back to us
            my $last_sent_msg;

            # loop across sending the bump_progress messages
            foreach my $engine_name ( @engines ) {
                # bump progress, bumps the progress bar
                $log->debug(LOGNAME . qq(: bumping progress: engine #)
                    . $loops . q(; ) . $engine_name);
                $mt->write_socket(
                    socket  => $client,
                    message => qq(bump_progress $engine_name),
                    sleep   => 1,
                );
                $log->debug(LOGNAME
                    . qq|: reading from client socket (bump progress reply)|);
                my $client_reply = $mt->read_socket($client);
                ## TEST
                ok($client_reply eq qq(OK bump_progress),
                    qq(received ACK for bump_progress message: $client_reply));
                # update status message
                $log->debug(LOGNAME . qq(: update status: foo #)
                    . $loops . q(; ) . $engine_name);
                $mt->write_socket(
                    socket  => $client,
                    message => qq(update_status $engine_name foo bar $loops),
                    sleep   => 1,
                );
                $log->debug(LOGNAME
                    . qq|: reading from client socket (update_status reply)|);
                $client_reply = $mt->read_socket($client);
                ## TEST
                ok($client_reply eq qq(OK update_status),
                    qq(received ACK for update_status message: $client_reply));
                $loops++;
            } # foreach my $engine_name ( @engines )

            # send init_complete
            $log->debug(LOGNAME . qq(: initialized all engine modules));
            $log->debug(LOGNAME . qq(: sending init_complete));
            $mt->write_socket(
                socket  => $client,
                message => q(init_complete),
            );

            $log->debug(LOGNAME
                . qq|: reading from client socket (init complete reply)|);
            my $init_ack = $mt->read_socket($client);
            ## TEST
            ok($init_ack eq q(OK init_complete),
                qq(client ACK'ed init_complete: $init_ack));

            $log->debug(LOGNAME . qq(: sending exit));
            $mt->write_socket(
                socket  => $client,
                message => qq(exit)
            );
            exit 0;

        } # while ( $client = $server->accept() )
    } # while (1)

# vim: filetype=perl shiftwidth=4 tabstop=4:
# конец!
