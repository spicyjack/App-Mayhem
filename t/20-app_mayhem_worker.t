#!perl -T

use strict;
use warnings;
use lib q(.); # picks up the directory that contains MayhemTest

diag( qq(\nTesting App::Mayhem::Worker $App::Mayhem::Worker::VERSION,\n)
    . qq(Perl $], $^X) );

#use Test::More tests => 1;
use Test::More qw(no_plan);
use Test::File;

use Time::HiRes qw(usleep);

use constant {
        LOGNAME => q(Test),
        API_VERSION => 0,
};

BEGIN {
    use_ok(q(threads));
    use_ok(q(File::Basename)); # used to find log4perl config file
    use_ok(q(IO::Socket::INET));
    use_ok(q(Log::Log4perl), qw(:easy :no_extra_logdie_message));
    use_ok(q(MayhemTest));
}

my $dirname = dirname($0);
## TEST
file_exists_ok(qq($dirname/tests.log4perl.cfg),
    q(log4perl config file exists for testing));
Log::Log4perl->init_once(qq($dirname/tests.log4perl.cfg));
my $log = Log::Log4perl->get_logger();
isa_ok($log, q(Log::Log4perl::Logger));
my $mt = MayhemTest->new();
isa_ok($mt, q(MayhemTest));

my $test_loops = 3;

    require_ok( q(App::Mayhem::Worker) );

    my $server_port = 8378;
    my $server_address = q(127.0.0.1);

    my $worker_thread = threads->create(
        sub {
            import App::Mayhem::Worker;
            App::Mayhem::Worker->new(
                server_address => $server_address,
                server_port => $server_port
                )->run(); # App::Mayhem::Worker->new
        } # sub
    ); # my $worker_thread = threads->create

    $worker_thread->detach();

    # some delay to test client reconnection attempts
    usleep(600);
    my $server = IO::Socket::INET->new(
        Listen      => 5,
        Timeout     => 500,
        Proto       => q(tcp),
        LocalPort   => $server_port,
        LocalAddr   => $server_address,
        ReuseAddr   => 1,
    );

    my $loops = 0;
    my $client_msg;
    while (1) {
        my $client;
        $log->debug(qq(test: parent PID $$: calling server->accept\n));
        while ( $client = $server->accept() ) {
            $log->debug(qq(test: accepted connection: )
                . $client->peerhost()
                . q(, )
                . $client->peerport()
                . qq(\n)
            );
            $client->autoflush(1);

            ### TEST
            isa_ok($client, q(IO::Socket::INET));

            $log->debug(LOGNAME . q(: waiting from HELLO message from worker));
            $client_msg = $mt->read_socket($client);
            ### TEST
            ok($client_msg =~ /HELLO Worker api_version \d+/,
                qq(Worker sent initial HELLO message: '$client_msg'));
            my $api_version = $client_msg;
            $api_version =~ s/.*(\d)$/$1/;
            ### TEST
            ok($api_version ge API_VERSION, qq(API Version from socket )
                . qq('$api_version' is greater than )
                . q(or equal to test API version: ') . API_VERSION . q('));

            $log->debug(LOGNAME . q(: sending ping message to worker));
            $mt->write_socket(
                socket  => $client,
                message => q(ping)
            );
            $log->debug(LOGNAME . q(: waiting for a ping ACK from the worker));
            $client_msg = $mt->read_socket($client);
            ### TEST
            ok($client_msg =~ /OK ping/,
                q(worker replied to ping with ) . qq('$client_msg') );

            $log->debug(LOGNAME . q(: waiting for a pong from the worker));
            $client_msg = $mt->read_socket($client);
            ### TEST
            ok($client_msg =~ /pong/,
                q(worker returned 'ping' with ) . qq('$client_msg') );

            $log->debug(LOGNAME . q(: sending get_mayhem_base_dir));
            $mt->write_socket(
                socket  => $client,
                message => qq(get_mayhem_base_dir)
            );
            $client_msg = $mt->read_socket($client);
            ### TEST
            ok($client_msg =~ /OK get_mayhem_base_dir/,
                qq(worker ACK'ed command: $client_msg) );

            ### TEST
            $client_msg = $mt->read_socket($client);
            ok($client_msg !~ /ERR/,
                q(worker thinks the mayhem base dir is:) . qq('$client_msg') );

            # seed the worker test with an inital echo message
            $log->debug(qq(test: sending echo message; $loops));
            my $sent_message = qq(this is sent message number $loops);
            $mt->write_socket(
                socket  => $client,
                message => q(echo ) . $sent_message,
            );

            while ( my $message = $mt->read_socket($client) ) {
                $loops++;
                ### TEST
                ok($message =~ /OK echo/,
                    qq(worker returned 'echo' with $message) );
                # get the reply
                $message = $mt->read_socket($client);
                ok($message eq $sent_message,
                    qq(echo reply from worker >$message<) );

                sleep 2;
                if ( $loops > $test_loops ) {
                    $log->debug(qq(test: reached client ping limit));
                    $mt->write_socket(
                        socket  => $client,
                        message => q(exit),
                    );
                    sleep 1;
                    exit 0;
                }
                $log->debug(qq(test: sending echo message; $loops));
                $sent_message = qq(this is sent message number $loops);
                $mt->write_socket(
                    socket  => $client,
                    message => q(echo ) . $sent_message,
                );
            } # while (<$client>)
        } # while ( $client = $server->accept() )
    } # while (1)
