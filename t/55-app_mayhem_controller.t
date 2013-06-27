#!perl -T

# test the mayhem controller module

# test plan
# - create simulated worker and splash threads
# - init the engine modules
#   - query the simworker thread for data
#   - ping the simsplash when the model is updated
# - check that the sequence diagram is being followed as far as who sends what
# when

package main;
# testing modules
use strict;
use warnings;

#use Test::More tests => 1;
use Test::File;
use Test::More qw(no_plan);
use Time::HiRes qw(usleep);

BEGIN {
    use_ok(q(threads));
    use_ok(q(IO::Socket::INET));
    use_ok(q(Log::Log4perl), qw(:no_extra_logdie_message));
    use_ok(q(File::Basename)); # used to find log4perl config file
    require_ok( q(App::Mayhem::Controller) );
    require_ok( q(App::Mayhem::Worker) );
} # BEGIN

my $dirname = dirname($0);
## TEST
file_exists_ok(qq($dirname/tests.log4perl.cfg),
    q(log4perl config file exists for testing));
Log::Log4perl->init_once(qq($dirname/tests.log4perl.cfg));
my $log = Log::Log4perl->get_logger();
my $client_name = q(Test);
diag( qq(\nTesting App::Mayhem::Controller )
    . qq($App::Mayhem::Controller::VERSION,\n)
    . qq(Perl $], $^X\n)
    . qq(I am thread #) . threads->tid() . qq(\n)
); # diag

### TEST GUTS ###

    my @engines = (
        q(ReMooD),
        q(Vavoom),
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

    my $worker_thread = threads->create(
        sub {
            import App::Mayhem::Worker;
            App::Mayhem::Worker->new(
                server_address  => $server_address,
                server_port     => $server_port
            )->run();
        } # sub
    ); # my $worker_thread = threads->create
    $worker_thread->detach();

    # enter the testing loop
    $log->debug($client_name . qq(: Parent PID is $$: calling server->accept));
    while (1) {
        my $client;
        while ( $client = $server->accept() ) {
            isa_ok($client, qq(IO::Socket::INET));
            $client->autoflush(1);
            $log->debug(qq($client_name accepted connection: )
                . $client->peerhost()
                . q(, )
                . $client->peerport()
                . qq(\n)
            ); # $log->debug

            my $client_msg = <$client>;
            chomp($client_msg);
            ## TEST
            ok($client_msg =~ /OK Worker/,
                qq(Worker sent initial OK message: $client_msg));

            $log->debug($client_name . q(: sending 'ping' to worker));
            print $client qq(ping\n);
            $client_msg = <$client>;
            chomp $client_msg;
            ## TEST
            ok($client_msg eq "OK ping", qq(worker OK's ping: '$client_msg'));

            # wait for the reply
            $client_msg = <$client>;
            chomp ($client_msg);
            ## TEST
            ok($client_msg eq q(pong), q(worker replied to ping with )
                . qq('$client_msg') );

            ### get_file_info
            $log->debug(qq(Test: sending 'get_file_info' command));
            print $client qq(get_file_info /dev/null\n);
            $client_msg = <$client>;
            chomp($client_msg);
            ## TEST
            ok($client_msg =~ /^OK get_file_info/,
                qq(get_file_info command was acknowledged: '$client_msg'));

            $client_msg = <$client>;
            chomp $client_msg;
            ## TEST
            ok($client_msg =~ /^file_info .*$/,
                qq(worker sent file_info reply: $client_msg));

            ### exit
            # close the socket to break out of this while loop
            $log->debug($client_name . q(: sending 'exit' message));
            print $client qq(exit\n);
            $server->close;
            $log->debug($client_name
                . q(: server->close called; exiting test.));
            exit 0;
        } # while ( $client = $server->accept() )
    } # while (1)

# конец!
