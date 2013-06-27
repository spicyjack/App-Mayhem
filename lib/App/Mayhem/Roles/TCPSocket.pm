package App::Mayhem::Roles::TCPSocket;

use Log::Log4perl qw(:levels :no_extra_logdie_message);
use Mouse::Role; # sets strict and warnings
use POSIX qw(strftime); # strftime function
use Time::HiRes qw(usleep);

use constant {
    LOGNAME => q(Socket),
};

=head1 NAME

App::Mayhem::Roles::TCPSocket - A role for helping manage TCP sockets and
things sent across sockets.

=head1 VERSION

Version 0.0.3

=cut

use version; our $VERSION = qv('0.0.3');

=head1 SYNOPSIS

A role for helping to set up a client socket.  Creates the socket object and
connects to the server's IP and port.

=head1 OBJECT METHODS

=head2 _handle_socket()

Required arguments:

=over

=item $socket

The socket to read from.

=back

Using the supplied socket, wait for a message to come in on that socket, then
handle the message appropriately, including calling any dispatch handler
methods as necessary.

Returns true (1) if the message was handled and the dispatch handler method
was called, returns false (0) and warns at the console if a dispatch handler
method for the received message doesn't exist.

=cut

#################################################
# App::Mayhem::Roles::TCPSocket->_handle_socket #
#################################################
sub _handle_socket {
    my $self = shift;
    my $socket = shift;

    # set up different objects
    my $log = Log::Log4perl->get_logger();
    my $socket_name = $self->_socket_name();
    my $socket_type = $self->_socket_type();
    $log->debug($socket_name . q( ) . $socket_type
        . q(: Entering _handle_socket));

    if ( $socket->connected() ) {
        my $peerinfo = $self->get_peer_ipport($socket);
        # grab the message from the socket
        my $message = <$socket>;
        $message =~ s/\015\012$//;
        $log->debug(qq($socket_name $socket_type)
            . qq(: Incoming message from $peerinfo;));
        $log->debug(qq($socket_name $socket_type)
            . qq(: Message contents; '$message'));
        my ($command, $args);
        # if $message has spaces, it's a complex command (has arguments)
        if ( $message =~ /\s/ ) {
            $message =~ /([a-zA-Z0-9\-_]+) (.*)/;
            $command = $1;
            $args = $2;
        } else {
            $command = $message;
        } # if ( $message =~ /\s/ )

        # the handler for a HELLO message
        if ( $command eq q(HELLO) ) {
            $log->debug(qq($socket_name $socket_type)
                . qq(: received HELLO message: $args));
            # three strings after the command string
            my ($remote_name, $api_ver_string, $remote_api_ver)
                = split(/ /, $args);
            $log->debug(qq($socket_name $socket_type)
                . qq(: returning 'HI' message to caller '$remote_name'));
            $self->_print_client_socket(
                socket_obj  => $socket,
                message     => qq(HI $remote_name $socket_name)
            );
            return 1;
        }

        # the reply to HELLO
        if ( $command eq q(HI) ) {
            my ($my_name, $remote_name) = split(/ /, $args);
            if ( $my_name eq $socket_name ) {
                $log->debug(qq($socket_name $socket_type)
                    . qq(: received HI from $remote_name));
                return 1;
            } else {
                $log->warn(qq($socket_name $socket_type)
                    . qq(: remote socket did not reply correctly to HELLO!));
                $log->warn(qq($socket_name $socket_type)
                    . qq(: got: my_name: $my_name, remote_name: $remote_name));
                return 0;
            }
        }

        # ACK messages, no action required
        if ( $command eq q(OK) ) {
            $log->debug(qq($socket_name $socket_type)
                . qq(: received 'OK', args '$args';));
            $log->debug(qq($socket_name $socket_type:)
                . q(waiting for more commands...));
            return 1;
        }
        # if this object has a method with the same name as the request, then
        # call that method with any arguments
        if ( $self->can($command) ) {
            $log->debug(qq($socket_name $socket_type)
                 . qq(: calling handler for '$command'));
            # send an OK back to the caller, meaning the commnand can be run and
            # is being run (for long-running commands)
            #$self->_print_socket(qq(OK $command));
            my $reply;
            if ( defined $args ) {
                $reply = $self->$command(
                    command_args    => $args,
                    socket_obj      => $socket,
                );
            } else {
                $reply = $self->$command( socket_obj => $socket );
            } # if ( defined $args )
            # return the data to the remote host that requested it
            if ( defined $reply ) {
                $self->_print_client_socket(
                    socket_obj  => $socket,
                    message     => $reply,
                );
                #$self->_print_socket($reply);
            }
            return 1;
        } else {
            $log->warn(qq($socket_name $socket_type)
                . qq(: command $command not handled));
            $self->_print_socket(qq(ERR $command not handled));
            return 0;
        } # if ( $self->can($command) )
    } else {
        $log->info(qq(Socket no longer connected));
    } # if ( $socket->connected() )
    return 0;
} # sub _handle_socket

=head2 get_host_ipport()

Required arguments:

=over

=item $socket

A L<IO::Socket::INET> object (or equivalent).

=back

For a given C<$socket>, returns the IP/port pair of the local host in the
format C<XX.XX.XX.XX:XXXX>.  Note that this method pulls the host information
from the socket object that is passed in to it, it does not retrieve any
attributes from any other objects.

=cut

##################################################
# App::Mayhem::Roles::TCPSocket->get_host_ipport #
##################################################
sub get_host_ipport {
    my $self = shift;
    my $socket = shift;

    if ( defined $socket->sockhost() && defined $socket->sockport() ) {
        return  $socket->sockhost() . q(:) . $socket->sockport();
    } else {
        return q(unknown local host/port);
    }
} # sub get_peer_ipport

=head2 get_peer_ipport()

Required arguments:

=over

=item $socket

A L<IO::Socket::INET> object (or equivalent).

=back

For a given C<$socket>, returns the IP/port pair of the local peer in the
format C<XX.XX.XX.XX:XXXX>.  Note that this method pulls the peer information
from the socket object that is passed in to it, it does not retrieve any
attributes from any other objects.

=cut

##################################################
# App::Mayhem::Roles::TCPSocket->get_peer_ipport #
##################################################
sub get_peer_ipport {
    my $self = shift;
    my $socket = shift;

    if ( defined $socket->peerhost() && defined $socket->peerport() ) {
        return  $socket->peerhost() . q(:) . $socket->peerport();
    } else {
        return q(unknown peer host/port);
    }
} # sub get_peer_ipport

=head2 add_client_socket()

Required arguments:

=over

=item $client_name

The name of this client; passed to the server during the initial connection,
so that the server can keep track of which client is sending data.

=item $client_socket

The socket object to store for this specific socket.

=back

The C<add_client_socket> method stores a client socket in this
L<App::Mayhem::Roles::TCPSocket> object, so that other objects can retrieve it
later on in order to send messages to clients.

The sockets are stored by client name (L<get_client_socket_by_name()>) or by
IP:port pair (L<get_client_name_by_ipport()>).

=cut

####################################################
# App::Mayhem::Roles::TCPSocket->add_client_socket #
####################################################
sub add_client_socket {
    my $self = shift;
    my %args = @_;

    my $log = Log::Log4perl->get_logger();

    $log->logdie( LOGNAME . qq(: add_client_socket method )
        . q(needs a client_socket argument!) )
        unless ( exists($args{client_socket}) );
    $log->logdie( LOGNAME . qq(: add_client_socket method )
        . q(needs a client_name argument!) )
        unless ( exists($args{client_name}) );

    my $client_name = $args{client_name};
    my $client_socket = $args{client_socket};
    my $client_ipport = $self->get_peer_ipport($client_socket);

    # grab the hash of client sockets
    my %name_sockets = %{$self->_client_sockets_by_name()};
    my %ipport_names = %{$self->_client_names_by_ipport()};
    if ( exists $name_sockets{$client_name}
        && exists $ipport_names{$client_ipport}) {
        $log->warn($self->_socket_name . qq(: add_client_socket: A socket )
            . qq(named $client_name already exists!));
    }
    # add this new socket to the list
    $name_sockets{$client_name} = $client_socket;
    $ipport_names{$client_ipport} = $client_name;
    # store the sockets hash back into the attribute
    $self->_client_sockets_by_name(\%name_sockets);
    $self->_client_names_by_ipport(\%ipport_names);
    return 1;
} # sub add_client_socket

=head2 get_client_socket_by_name

Required arguments:

=over

=item $socket_name

The client name of the socket object to return.

=back

Returns the L<IO::Socket::INET> object requested using the C<$socket_name>
argument, or C<undef> if the socket does not exist.

=cut

############################################################
# App::Mayhem::Roles::TCPSocket->get_client_socket_by_name #
############################################################
sub get_client_socket_by_name {
    my $self = shift;
    my $client_name = shift;
    my $log = Log::Log4perl->get_logger();

    $log->debug($self->_socket_name
        . qq( get_client_socket_by_name; args: $client_name));
    my %sockets = %{$self->_client_sockets_by_name()};
    if ( ! exists $sockets{$client_name} ) {
        $log->info($self->_socket_name . qq( get_client_socket_by_name: )
            . qq($client_name does not exist!));
        return undef;
    } else {
        return $sockets{$client_name};
    }
} # sub get_client_socket_by_name

=head2 get_client_name_by_ipport

Required arguments:

=over

=item $socket_ipport

The IP:port information for a specific client.

=back

Returns the client name for a given C<$socket_ipport> argument, or C<undef> if
the client name does not exist.

=cut

############################################################
# App::Mayhem::Roles::TCPSocket->get_client_name_by_ipport #
############################################################
sub get_client_name_by_ipport {
    my $self = shift;
    my $client_ipport = shift;
    my $log = Log::Log4perl->get_logger();

    $log->debug($self->_socket_name
        . qq( get_client_name_by_ipport; args: $client_ipport));
    my %sockets = %{$self->_client_names_by_ipport()};
    if ( ! exists $sockets{$client_ipport} ) {
        $log->info($self->_socket_name . qq( get_client_name_by_ipport: )
            . qq($client_ipport does not exist!));
        return "Unknown host"
    } else {
        return $sockets{$client_ipport};
    }
} # sub get_client_name_by_ipport

=head2 _client_socket_setup()

Required arguments:

=over

=item $socket_name

The name of this client; passed to the server during the initial connection,
so that the server can keep track of which client is sending data.

=back

The C<_client_socket_setup()> method initializes a socket object, attempts to
connect the socket to the server.

=cut

#######################################################
# App::Mayhem::Roles::TCPSocket->_client_socket_setup #
#######################################################
sub _client_socket_setup {
    my $self = shift;
    my %args = @_;

    my ($socket_name, $api_version);
    my $log = Log::Log4perl->get_logger();

    $log->logdie( LOGNAME . qq(: _client_socket_setup method )
        . q(needs a socket_name argument!) )
        unless ( exists($args{socket_name}) );

    $log->logdie( LOGNAME . qq(: _client_socket_setup method )
        . q(needs a api_version argument!) )
        unless ( exists($args{api_version}) );

    $socket_name = $args{socket_name};
    $api_version = $args{api_version};
    $log->debug(q(Socket: Entering ->_client_socket_setup; ));
    $log->debug(qq(- socket name: $socket_name, API version: $api_version));

    # these attributes are documented below
    $self->_socket_name($socket_name);
    $self->_socket_type(q(client));
    $self->_api_version($api_version);

    my $connection_attempts = 3;
    my $connection_tries = 1;
    my $socket;
    while ( ! defined $socket ) {
        $socket = IO::Socket::INET->new(
            PeerAddr    => $self->server_address(),
            PeerPort    => $self->server_port(),
            Proto       => q(tcp),
        );
        $connection_tries++;
        if ( ! defined $socket ) {
            my $random_sleep = ( int(rand(6)) + 1 ) * 100;
            $log->info(q(server not available on port ) . $self->server_port());
            $log->info(qq(sleeping for $random_sleep microseconds));
            if ( $connection_tries == $connection_attempts ) {
                $log->logdie(qq(unable to contact server after )
                    . qq( $connection_attempts attempts));
            }
            usleep($random_sleep);
            next;
        }
        $log->debug($socket_name . q( socket: connected to server));
        $log->debug($socket_name . q( socket: local host/port: )
            . $self->get_host_ipport($socket) );
        $log->debug($socket_name . q( socket: remote host/port: )
            . $self->get_peer_ipport($socket) );
    } # while ( ! defined $socket && $connection_attempts < 3 )

    # stash the socket inside of $self
    $self->_socket($socket);
} # sub _client_socket_setup

=head2 _send_client_hello()

Required arguments: None

Sends the C<HELLO> message from the client to the server.

=cut

#####################################################
# App::Mayhem::Roles::TCPSocket->_send_client_hello #
#####################################################
sub _send_client_hello {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    $log->debug($self->_socket_name . q(: Entering ->_send_client_hello; ));
    $log->debug(q(- socket name: ) . $self->_socket_name
        . q(, API version: ) . $self->_api_version);

    # tell the server that we're up
    $log->debug($self->_socket_name
        . q( socket: sending 'HELLO ) . $self->_socket_name . q('));
    $self->_print_socket(qq(HELLO )
        . $self->_socket_name . q( api_version ) . $self->_api_version);
} # sub _send_client_hello

=head2 _server_socket_setup()

Required arguments:

=over

=item $socket_name

The name of this client; passed to the server during the initial connection,
so that the server can keep track of which client is sending data.

=back

The C<_server_socket_setup()> method initializes a socket object, attempts to
connect the socket to the server.

=cut

#######################################################
# App::Mayhem::Roles::TCPSocket->_server_socket_setup #
#######################################################
sub _server_socket_setup {
    my $self = shift;
    my $socket_name = shift;
    my $log = Log::Log4perl->get_logger();

    if ( ! defined $socket_name ) {
        die qq(_server_socket_setup method needs a socket name!);
    } # if ( ! defined $socket_name )

    $log->debug(q(Socket: Entering ->_server_socket_setup; )
        . qq(socket name: $socket_name));

    # create the socket that accepts new requests (the server)
    my $socket = IO::Socket::INET->new(
        Listen      => 5,
        Timeout     => 10,
        Proto       => q(tcp),
        LocalPort   => $self->server_port(),
        LocalAddr   => $self->server_address(),
        ReuseAddr   => 1,
    );
    # these attributes are documented below
    $self->_socket($socket);
    $self->_socket_type(q(listener));
    $self->_socket_name($socket_name);
    return $self;
} # sub _server_socket_setup

=head2 _print_client_socket()

Outputs some text to a specific client socket socket connection, adding
network-friendly end-of-line characters as appropriate.

Required arguments:

=over

=item $socket_name

The name of the socket to send the message to.

=item $socket_msg

The message to print to the socket, which could be a command or a response
message of some kind.  Returns true (C<1>) if printing to the socket was
successful.

=back

=cut

#######################################################
# App::Mayhem::Roles::TCPSocket->_print_client_socket #
#######################################################
sub _print_client_socket {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    $log->logdie(LOGNAME . qq(: _print_client_socket method )
        . q(needs a message argument!) )
        unless ( exists($args{message}) );

    $log->logdie(LOGNAME . qq(: _print_client_socket method )
        . q(needs a socket_obj argument!) )
        unless ( exists($args{socket_obj}) );

    my $message = $args{message};
    my $client_socket = $args{socket_obj};
    my $client_ipport = $self->get_peer_ipport($client_socket);
    my $client_name = $self->get_client_name_by_ipport($client_ipport);

    $log->debug($self->_socket_name . qq( _print_client_socket: peer info: )
        . $client_ipport);
    $log->debug($self->_socket_name . qq( _print_client_socket: peer name: )
        . $client_name);
    $log->debug($self->_socket_name . qq( _print_client_socket: sending: )
        . $message );
    # as suggested by http://perldoc.perl.org/perlport.html#Newlines
    print $client_socket qq($message\015\012);
    return 1;
} # sub _print_client_socket

=head2 _print_socket()

Outputs some text to an existing socket connection, adding network-friendly
end-of-line characters as appropriate.

Required arguments:

=over

=item $socket_msg

The message to print to the socket, which could be a command or a response
message of some kind.  Returns true (C<1>) if printing to the socket was
successful.

=back

=cut

################################################
# App::Mayhem::Roles::TCPSocket->_print_socket #
################################################
sub _print_socket {
    my $self = shift;
    my $message = shift;
    my $log = Log::Log4perl->get_logger();

    my $socket = $self->_socket();
    $log->logdie(qq(Socket object for ) . $self->_socket_name
        . q( undefined!))
        unless ( defined $socket );
    $log->debug( $self->_socket_name . qq( _print_socket: peer info: )
        . $self->get_peer_ipport($socket) );
    $log->debug($self->_socket_name . qq( _print_socket: message: $message));
    # as suggested by http://perldoc.perl.org/perlport.html#Newlines
    print $socket qq($message\015\012);
    return 1;
} # sub _print_socket

=head1 DEFAULT SOCKET COMMANDS

A default set of commands that can be called via TCP sockets to this object,
causing objects that implement this L<Mouse> role to perform the requested
action.

=head2 ping

Reply to the requestor with C<pong> as a way of testing availability.

Required arguments: None.

=for wiki
|| `ping` || any || `pong` || generic connectivity test ||

=cut

#######################################
# App::Mayhem::Roles::TCPSocket->ping #
#######################################
sub ping {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    my $socket_name = $self->_socket_name();
    $log->logdie($socket_name . qq(: ping )
        . q(needs a remote_socket argument!) )
        unless ( exists($args{remote_socket}) );

    $log->debug(qq($socket_name socket: received ping from: )
        . $self->server_address());
    $log->debug(qq($socket_name socket: sending a 'pong' message));
    return qq(pong);
} # sub ping

=head2 exit

Exit this thread.  Called by the controller when the program is about to quit.

Required arguments: None.

=for wiki
|| `exit` || any || N/A || exit thread; client needs to send OK before
exiting??? ||

=cut

#######################################
# App::Mayhem::Roles::TCPSocket->exit #
#######################################
sub exit {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    my $socket_name = $self->_socket_name();
    $log->logdie($socket_name . qq(: exit )
        . q(needs a remote_socket argument!) )
        unless ( exists($args{remote_socket}) );

    $log->debug(qq($socket_name socket: received exit command from: )
        . $self->server_address());
    threads->exit();
} # sub exit

=head2 echo

Echo the text received from the sender back to the sender.

Required arguments:

=over

Text to be echoed back to the sender.

=back

=cut

#######################################
# App::Mayhem::Roles::TCPSocket->echo #
#######################################
sub echo {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    my $socket_name = $self->_socket_name();
    $log->logdie($socket_name . qq(: echo )
        . q(needs a remote_socket argument!) )
        unless ( exists($args{remote_socket}) );
    $log->logdie($socket_name . qq(: echo )
        . q(needs a command_args argument!) )
        unless ( exists($args{command_args}) );

    my $command = $args{command_args};
    $log->debug(qq($socket_name socket: echo: argument is '$command'));
    return $command;
} # sub echo


=head1 OBJECT ATTRIBUTES

=head2 server_address

IP address to connect to contact the controller object.  Defaults to localhost
(C<127.0.0.1>).

=cut

has q(server_address)   => (
    is                  => q(ro),
    isa                 => q(Str),
    default             => q(127.0.0.1),
); # has q(server_address)

=head2 server_port

Port number to connect to contact the controller object.  Defaults to port
C<6666> TCP.

=cut

has q(server_port)      => (
    is                  => q(ro),
    isa                 => q(Int),
    default             => q(6666),
);

# for storing a socket connection
has q(_socket)          => (
    is                  => q(rw),
    isa                 => q(FileHandle),
);

# for storing the name of the client that this socket services
has q(_socket_name)     => (
    is                  => q(rw),
    isa                 => q(Str),
);

# for storing the type of socket, client or server
has q(_socket_type)     => (
    is                  => q(rw),
    isa                 => q(Str),
);

# storing the API version that the client and/or server code speaks
has q(_api_version)     => (
    is                  => q(rw),
    isa                 => q(Int),
);

has q(_client_sockets_by_name)  => (
    is                  => q(rw),
    isa                 => q(HashRef[FileHandle]),
    default             => sub{ {} },
);

has q(_client_names_by_ipport)  => (
    is                  => q(rw),
    isa                 => q(HashRef[Str]),
    default             => sub{ {} },
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

    perldoc App::Mayhem::Roles::TCPSocket

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

# vim: filetype=perl shiftwidth=4 tabstop=4:
1; # End of App::Mayhem::Roles::TCPSocket
