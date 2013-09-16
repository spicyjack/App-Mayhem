package App::Mayhem::View;

# systemwide modules
use Log::Log4perl qw(:levels);
use Mouse; # sets strict and warnings
use POSIX qw(strftime); # strftime function
use Time::HiRes qw(usleep);
# local modules
use App::Mayhem::View::SplashScreen;
use App::Mayhem::View::MainMenu;

use constant {
    LOGNAME     => q(View),
    API_VERSION => 1,
};

# NOTE: App::Mayhem::Roles::TCPSocket provides server_address and server_port
# attributes, along with a bunch of socket operations
with qw(
    App::Mayhem::Utils
    App::Mayhem::Roles::TCPSocket
);

=head1 NAME

App::Mayhem::View - A herder of dialogs.  This object creates the
L<App::Mayhem::View::SplashScreen> and L<App::Mayhem::View::MainMenu> dialogs
as requested by the controller and displays them for the user.  Also accepts
other commands from the controller, and sendѕ user feedback to the controller.

=head1 VERSION

Version 0.0.1

=cut

use version; our $VERSION = qv('0.0.1');

=head1 SYNOPSIS

This object manages the GUI screens that are presented to the user, creating
and destroying toplevel dialogs as needed to help the user use the program.
This object manages the TCP socket object that is used to communicate with the
controller object L<App::Mayhem>.

    my $gui_thread = threads->create(
        sub {
            require App::Mayhem::View;
            import App::Mayhem::View;
            App::Mayhem::View->run();
        } # sub
    );
    $gui_thread->detatch();

=head1 OBJECT METHODS

=head2 new()

Optional arguments:

=over

=item server_port => [port number]

Port number that the controller object is listening to.

=item server_address => [IPv4 address]

IP address that the controller object is listening to.

=back

The C<new()> method initializes the UI Manager object and causes it to connect
to the server on the specified address/port and wait for the server to issue
commands.

=head2 run()

Required arguments: None.

Transfer control to the UI Manager object.  Does not return program execution
to the caller; this method is meant to be called under a separate process
thread, which can then be detatched.

=cut

###############################
# App::Mayhem::View->run #
###############################
sub run {
    my $self = shift;
    my $log = get_logger();

    $log->debug(LOGNAME . q(: Entering ->run));
    $log->debug(LOGNAME . q(: I am thread #) . threads->tid() );

    $log->debug(LOGNAME . q(: Launching splashscreen;));
    my $splash = App::Mayhem::View::SplashScreen->new();
    $log->debug(LOGNAME . q(: Launching main menu;));
    my $mainmenu = App::Mayhem::View::MainMenu->new(
        layout => $self->layout
    );

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

=head1 OBJECT ATTRIBUTES

=head2 layout

String representing whic layout will be used for displaying user interfaces;
one of C<compact> or C<larger>.

=cut

has q(layout) => (
    is      => q(rw),
    isa     => q(Str),
    default => q(compact),
);

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

Copyright (c) 2011 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::Mayhem::View
