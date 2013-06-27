package App::Mayhem::Worker;

use Log::Log4perl qw(:levels);
use Mouse; # sets strict and warnings
use POSIX qw(strftime); # strftime function
use Time::HiRes qw(usleep);

use constant {
    LOGNAME     => q(Worker),
    API_VERSION => 1,
};

with qw(
    App::Mayhem::Utils
    App::Mayhem::Roles::TCPSocket
);

=head1 NAME

App::Mayhem::Worker - A worker thread object.

=head1 VERSION

Version 0.0.1

=cut

use version; our $VERSION = qv('0.0.1');

=head1 SYNOPSIS

Performs expensive I/O operations at the request of other threads.  Connects
to a controller thread via a TCP socket in order to receive requests to
perform work.

    my $worker_thread = threads->create(
        sub {
            require App::Mayhem::Worker;
            import App::Mayhem::Worker;
            App::Mayhem::Worker->new()->run();
        } # sub
    ); # my $worker_thread = threads->create
    $worker_thread->detatch();

=head1 OBJECT METHODS

=head2 new()

Required arguments:

=over

=item server_port => [port number]

Port number that the controller object is listening to.

=item server_address => [IPv4 address]

IP address that the controller object is listening to.

=back

The C<new()> method initializes the worker object and causes it to connect to
the server on the specified address/port and wait for the server to issue
commands.

=head2 run()

Required arguments: None.

Transfer control to the worker object.  Does not return program execution to
the caller; this method is meant to be called from a separate process thread,
which can then be detatched.

=cut

############################
# App::Mayhem::Worker->run #
############################
sub run {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: Entering ->run));
    $log->debug(LOGNAME . q(: I am thread #) . threads->tid() );
    # set up the socket connection to the server so commands can be sent
    $self->_client_socket_setup(
        socket_name     => LOGNAME,
        api_version     => API_VERSION,
    );

    # send the hello message
    $self->_send_client_hello();

    # this should be set up by $self->_setup_socket() above
    my $socket = $self->_socket();

    while ( defined $socket ) {
        # this should block...
        my $msg_status = $self->_handle_socket($socket);
        # if $msg_status is false, there was an error
        if ( ! $msg_status ) {
            $log->warn(LOGNAME . qq(: handle_socket returned $msg_status; ));
        } # if ( $msg_status > 0 )
    } # while ( defined $worksock )
} # run

=head2 get_file_info()

Required arguments:

=over

=item filename => $filename

Check I<filename> and verify it exists on the filesystem.

=cut

######################################
# App::Mayhem::Worker->get_file_info #
######################################
sub get_file_info {
    my $self = shift;
    # FIXME new command structure
    my $arg = shift;
    my $log = Log::Log4perl->get_logger();

    # this should be set up by $self->_setup_socket() above
    my $worksock = $self->_socket();
    $log->debug(LOGNAME . qq(: get_file_info: got $arg));
    $log->debug(LOGNAME . qq(: sleeping for 2 seconds...));
    sleep 2;
    return qq(file_info "foo foo foo"\n);
} # sub _get_file_info

=head1 AUTHOR

Brian Manning, C<< <brian at portaboom dot com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<mayhem-launcher@googlegroups.com>, or through the web interface at
L<http://code.google.com/p/mayhem-launcher/issues/list>.  I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Mayhem


You can also look for information at:

=over 4

=item * Mayhem Launcher project page

L<http://code.google.com/p/mayhem-launcher>

=item * Mathem Launcher issues (bugs) page

L<http://code.google.com/p/mayhem-launcher/issues/list>

=item * Mayhem Launcher Google Groups page

L<http://groups.google.com/group/mayhem-launcher>

=back

=head1 ACKNOWLEDGEMENTS

Perl, Gtk2-Perl team, the Doom Wiki L<http://doom.wikia.com> for lots of the
documentation, all of the various Doom source porters, and id Software for
releasing the source code for the rest of us to make merry mayhem with.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2011 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::Mayhem::Worker
