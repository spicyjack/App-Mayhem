package App::Mayhem::Roles::Controller;

use Log::Log4perl qw(:levels :no_extra_logdie_message);
use Mouse::Role; # sets strict and warnings
use POSIX qw(strftime); # strftime function

use constant {
    LOGNAME => q(Controller)
};

=head1 NAME

App::Mayhem::Roles::Controller - A controller object that controls other Mayhem
objects (splashscreen, worker).

=head1 VERSION

Version 0.0.1

=cut

use version; our $VERSION = qv('0.0.1');

=head1 SYNOPSIS

A blank module to be used as a template stub for new modules.  This module
should just "do the needful".

    package MyPackage;

    use Mouse;
    extends 'App::Mayhem::Roles::Controller';

=head1 OBJECT METHODS

=head2 mayhem_event()

Required arguments:

=over

=item command_args

The event sent by the remote client.

=back

An event sent by a remote client, which may or may not need special handling.

=cut

sub mayhem_event {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    my $socket_name = $self->_socket_name();
    $log->logdie($socket_name . qq(: mayhem_event )
        . q(needs a socket_obj argument!) )
        unless ( exists($args{socket_obj}) );
    $log->logdie($socket_name . qq(: mayhem_event )
        . q(needs a command_args argument!) )
        unless ( exists($args{command_args}) );

    $log->debug(LOGNAME . q(: Entering 'mayhem_event'));
    $log->debug(LOGNAME . q(: NOT sending 'OK mayhem_event'));
    my $socket = $args{socket_obj};
    my $command = $args{command_args};

    if ( $command =~ /splashscreen_exit/ ) {
        sleep 3;
        exit 0;
    } else {
        $log->logdie(q(Received unknown mayhem_event command));
    }
    return undef;
}

=head2 get_max_progress_value()

Required arguments: None

Returns the number of modules that need to be initialized.  The splash screen
will use this number in order to draw the progress bar control.

=cut

sub get_max_progress_value {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: Handling 'get_max_progress_value'));
    $log->debug(LOGNAME . q(: Sending 'OK get_max_progress_value'));
    my $socket = $args{socket_obj};

    ## ACK
    $self->_print_client_socket(
        message     => q(OK get_max_progress_value),
        socket_obj  => $socket,
    );
    my @runnable_engines = $self->meta_get_runnable_engines_list();
    $log->debug(LOGNAME . q(: returning 'set_max_progress_value ) .
        scalar(@runnable_engines) . q('));
    # return this so it gets sent to through the socket to the remote host
    #sleep 1;
    return q(set_max_progress_value ) . scalar(@runnable_engines);
} # sub get_max_progress_value

=head2 init_all_engines()

Required arguments: None

Initializes modules that wrap different game engines.

=cut

sub init_all_engines {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    my $socket_name = $self->_socket_name();
    $log->logdie($socket_name . qq(: init_all_engines )
        . q(needs a socket_obj argument!) )
        unless ( exists($args{socket_obj}) );

    $log->debug(LOGNAME . q(: Entering 'init_all_engines'));
    $log->debug(LOGNAME . q(: Sending 'OK init_all_engines'));
    my $socket = $args{socket_obj};
    ## ACK
    $self->_print_client_socket(
        message     => q(OK init_all_engines),
        socket_obj  => $socket,
    );
    sleep 2;

    my @runnable_engines = $self->meta_get_runnable_engines_list();
    foreach my $engine ( @runnable_engines ) {
        $log->debug(LOGNAME . qq(: initializing $engine));
        $self->_print_client_socket(
            message     => q(update_status Initializing ) . $engine . q(...),
            socket_obj  => $socket
        );
        my $reply = <$socket>;
        sleep 2;
        $self->_print_client_socket(
            message     => qq(bump_progress $engine),
            socket_obj  => $socket
        );
        $reply = <$socket>;
    }
    # we're done, tell the splash screen so it can do it's thing
    return q(init_complete);
} # sub get_max_progress_value

=head1 OBJECT ATTRIBUTES

=head2 engines_hash

A hash of engines that can be enumerated over.

=cut

has q(engines_hash)   => (
    is              => q(rw),
    isa             => q(HashRef[Object]),
    default         => sub { {} },
);
=head2 current_engine

The currently selected engine that will be used by the launcher.

=cut

has q(current_engine)   => (
    is              => q(rw),
    isa             => q(Str),
    default         => q(),
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

Copyright (c) 2010-2011 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::Mayhem::Roles::Controller
