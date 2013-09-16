package App::Mayhem;
# external packages
use File::Find::Rule;
use Getopt::Long;
use IO::Select;
use IO::Socket::INET;
use Log::Log4perl qw(:levels :no_extra_logdie_message);
use Mouse; # sets strict and warnings
use Pod::Usage;
use POSIX qw(strftime); # strftime function
use threads;
use threads::shared;

use constant {
    LOGNAME         => q(Mayhem),
    SELECT_TIMEOUT  => .5,
};

=head1 NAME

App::Mayhem - The Mayhem Launcher

=head1 VERSION

Version v0.0.4

=cut

use version;
our $VERSION = qv('0.0.5');
our $RELEASE_DATE = q(08Sep2011);
our $RELEASE_VERSION = q(2011.1);


# App::Mayhem::Utils - lists of attributes and dumping documentation
# App::Mayhem::Meta - metadata, images, glade XML files, gtkrc files
with qw(
    App::Mayhem::Utils
    App::Mayhem::Roles::Meta
    App::Mayhem::Roles::Controller
    App::Mayhem::Roles::TCPSocket
); # with

# current version of the configuration file
my $_config_version = 1;

# a list of modules to skip printing out the docs for
my @_module_blacklist = qw(App::Mayhem::Engine::Doom);

=head1 SYNOPSIS

A launcher of classic first-person shooters (FPS).

=head1 OPTIONS

 General options:
 -h|--help       Displays script options and usage
 -l|--loglevel   Script logging level; DEBUG, INFO, WARN
 -d|--debug      Shortcut for --loglevel=DEBUG
 --nocolorize    Don't colorize script log output

 Config file generation:
 -g|--generate   Generate a config file and exit
 -s|--short-cfg  Generate a short config (no comments) and exit

 Layout options:
 -k|--compact    Use the compact GUI interface
 --layout        Use this layout (options: compact, larger)

=cut

######################
# App::Mayhem->BUILD #
######################
sub BUILD {
    # called after the object is constructed, but before it's returned to the
    # caller
    my $self = shift;

    my %opts;
    # set colorized logs by default
    $opts{colorize} = 1;
    my $p = Getopt::Long::Parser->new();
    $p->getoptions(
        \%opts,
        # script options
        q(debug|D|d),
        q(help|h),
        q(compact|k),
        # logging options
        q(loglevel|log|level|ll=s),
        q(colorize!),
        # config file options
        q(generate|gen-config|gen|g),
        q(short|short-config|s),
    ); # $p->getoptions

    $self->{_opts} = \%opts;
    # if --help was called, print help output via Pod::Usage
    if ( defined $opts{help} ) {
        pod2usage( { -verbose => 1, -exitval => 0, -input => __FILE__ } );
    } # if ( defined $opts{help} )
    # set up the logger; we need this done so other methods/modules can have a
    # logger to log against
    my $logger_conf = qq(log4perl.rootLogger = INFO, Screen\n);
    if ( defined $opts{colorize} && $opts{colorize} == 1 ) {
        $logger_conf .= qq(log4perl.appender.Screen = )
            . qq(Log::Log4perl::Appender::ScreenColoredLevels\n);
    } else {
        $logger_conf .= qq(log4perl.appender.Screen = )
            . qq(Log::Log4perl::Appender::Screen\n);
    } # if ( $Config->get(q(colorlog)) )

    # FIXME each logger should get it's own conf with it's name as part of the
    # log message
    # format of the %d{} construct: http://tinyurl.com/63ta6mw
    $logger_conf .= qq(log4perl.appender.Screen.stderr = 1\n)
        . qq(log4perl.appender.Screen.layout = PatternLayout\n)
        . q(log4perl.appender.Screen.layout.ConversionPattern = )
        . q([%6r] %p %m%n)
        #. q(%d{ddMMMyyyy HH:mm.SSSSSS} %p %m%n)
        . qq(\n);
    #log4perl.appender.Screen.layout.ConversionPattern
    # = %d %p> %F{1}:%L %M - %m%n
    # create the logger object
    Log::Log4perl::init( \$logger_conf );
    my $log = Log::Log4perl->get_logger("");
    # $WARN by default
    if ( defined $opts{loglevel} ) {
        # FIXME check loglevel prior to using it
        $log->level($opts{loglevel});
    } else {
        $log->level($WARN);
    }
    if ( defined $opts{debug} ) {
        $log->level($DEBUG);
    } # if ( defined $opts{DEBUG} )

    if ( $opts{generate} or $opts{short} ) {
        # load all of the sub-modules, then call $self->get_documentation
        # on those submodules in order to dump the docs to STDOUT
        $self->_dump_configuration();
        exit 0;
    } # if ( $cfg_generate )

    $log->debug(q(=============== ) . __PACKAGE__ . q( ===============));
    $log->debug(qq(Release version: $RELEASE_VERSION, $RELEASE_DATE));
    $log->debug(LOGNAME . qq(: My PID is $$\n));
    $log->debug(LOGNAME . q(: I am thread #) . threads->tid() );
    $log->debug(q(==== Begin script startup sequence ====));
} # sub BUILD

# $mayhem->new() == $mayhem->BUILD()

=head1 OBJECT METHODS

=head2 new

Sets up the L<Log::Log4Perl> logger, as well as different files and data
structures Mayhem needs to function.

    use App::Mayhem;

    my $mayhem = App::Mayhem->new();
    $mayhem->run();


=head2 run

Transfers program control to the Mayhem launcher.

=cut

####################
# App::Mayhem->run #
####################
sub run {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();
    my %opts = %{$self->{_opts}};

    # set the environment variable, so all of the dialogs don't have to do it
    # themselves
    $log->debug(qq(Setting GTK2_RC_FILES environment variable));
    $ENV{q(GTK2_RC_FILES)} = $self->meta_get_resource_path(q(file_gtkrc));

    # create the socket that accepts new requests (the server)
    my $server = $self->_server_socket_setup(LOGNAME);
    my $select = IO::Select->new();
    my $listener = $server->_socket();

    # start a worker thread
    $log->debug(LOGNAME . qq(: Creating Worker thread object));
    my $worker_thread = threads->create(
        sub {
            # FIXME lazy_use is broken, because App::Mayhem::Worker is not in
            # the @INC path anywhere; use lib __FILE__???
            #$self->lazy_use(q(App::Mayhem::Worker));
            require App::Mayhem::Worker;
            import App::Mayhem::Worker;
            App::Mayhem::Worker->new()->run();
        } # sub
    ); # my $worker_thread = threads->create
    $worker_thread->detach();
    my $worker_socket = $listener->accept();
    my $workerinfo =  $self->get_peer_ipport($worker_socket);
    $log->debug(LOGNAME .
        qq(: Accepted socket connection from Worker: $workerinfo));
    $worker_socket->autoflush(1);
    # wait for HELLO message
    if ( ! $self->_handle_socket($worker_socket) ) {
        $log->logdie(qq(HELLO message not received));
    }
    # then add the socket to the select object
    $select->add($worker_socket);

    my $layout;
    if ( defined $opts{compact} ) {
        $layout = q(compact);
    } elsif ( defined $opts{layout} ) {
        $layout = $opts{layout};
    } else {
        $layout = q(larger);
    }
    # start a GUI thread
    $log->debug(LOGNAME . qq(: Creating GUI thread object));
    my $gui_thread = threads->create(
        sub {
            $log->debug(LOGNAME . q(: Launching UI Manager;));
            require App::Mayhem::View;
            import App::Mayhem::View;
            App::Mayhem::View->new(layout => $layout);
        } # sub
    ); # my $gui_thread = threads->create
    $gui_thread->detach();
    my $splash_socket = $listener->accept();
    $self->add_client_socket(
        client_name     => q(Splash),
        client_socket   => $splash_socket,
    );
    my $splashinfo =  $splash_socket->peerhost()
        . q(:) . $splash_socket->peerport();
    $log->debug(LOGNAME
        . qq(: Accepted socket connection from Splash: $splashinfo));
    $splash_socket->autoflush(1);
    # handle the hello message
    if ( ! $self->_handle_socket($splash_socket) ) {
        $log->logdie(qq(HELLO message not received from Splash));
    }
    # then add the Splash screen to the select object
    $select->add($splash_socket);

    # accept connections from clients, which could be the file thread or the
    # GUI thread
    while (1) {
        #$select->add($listener);
        my @sockets;
        $log->debug(LOGNAME . q(: calling $select->can_read...));
        while ( @sockets = $select->can_read(SELECT_TIMEOUT) ) {
            $log->debug(LOGNAME . qq(: can_read: looping across sockets...));
            $log->debug(LOGNAME . q(: ) . scalar(@sockets)
                . q( sockets can be read));
            # loop across all of the sockets that can be read
            foreach my $fh ( @sockets ) {
                # is the listener able to read, i.e. do we have a new
                # connection?
#                my $clientinfo;
#                if ( $fh == $listener ) {
#                    $log->debug(LOGNAME
#                        . qq(: Accepting new socket connection;));
                    # yes, a new connection; handle
#                    my $client = $listener->accept();
#                    $clientinfo =  $client->peerhost() . q(:)
#                        . $client->peerport();
#                    $log->debug(LOGNAME . qq(: accepted connection from: )
#                        . qq($clientinfo\n)
#                    );
#                    $client->autoflush(1);
#                    $log->debug(LOGNAME . qq(: adding client to IO::Select));
#                    $select->add($client);
#                } else {
                    # no, existing connection stored in IO::Select is ready to
                    # read
                    $log->debug(LOGNAME
                        . qq(: Reading incoming message from filehandle #)
                        . fileno($fh));
                    my $msg_status = $self->_handle_socket($fh);
#                } # if ( $fh = $listener )
#                $log->debug(LOGNAME . qq(: finished read loop));
#                if ( defined $clientinfo ) {
#                    $log->debug(LOGNAME . qq( for remote client: )
#                        . $clientinfo);
#                }
            } # foreach $fh ( @sockets )
        } # while ( @sockets = $select->can_read($listener) )
    } # while (1)
} # sub run

####################################
# App::Mayhem->_dump_configuration #
####################################
sub _dump_configuration {
    my $self = shift;
    my %opts = %{$self->{_opts}};
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: Entering ->_dump_configuration));
    my @module_list = $self->meta_get_runnable_engines_list();
    # get the topmost config file header block
    my $output = $self->config_block_header() . qq(\n);
    $output .= $self->get_default_config();
    foreach my $module ( @module_list ) {
        $log->debug(LOGNAME . qq(: requiring $module));
        eval "require $module";
        # this Mouse-ifies the module
        my $object = $module->new();
        $output .= $object->config_block_header() . qq(\n);
        if ( $object->can(q(get_default_config)) ) {
            $output .= $object->get_default_config();
        } # if ( $object->can(q(get_documentation)) )
    } # foreach $module ( @module_list )
    # if a short config was requested, don't print everything, just the config
    # variables and block headers
    if ( $opts{short} ) {
        my $massaged_output;
        my @lines = split(qq(\n), $output);
        foreach my $line ( @lines ) {
            if ( $line !~ /^# / ) {
                next if ( $line =~ /^$/ );
                $massaged_output .= $line . qq(\n);
            } # if ( $line !~ /^# / )
        } # foreach my $line ( @lines )
        $output = $massaged_output;
    } # if ( $opts{short} )
    print $output;
} # sub _dump_configuration

=head1 OBJECT ATTRIBUTES

=head2 config_block_header

The text used for the header in a configuration block.

=cut

has q(config_block_header)   => (
    is              => q(ro),
    isa             => q(Str),
    default         =>
        qq(## Mayhem configuration file\n)
        . qq(## version $_config_version, generated )
        . POSIX::strftime( q(%c), localtime() ) . qq(\n)
        . qq(## comments are any lines that start )
        . qq(with the '#' or ';' symbols\n\n)
        . qq([Global]),
); # has q(config_block_header)

=head2 default_mirror_uri

The default C<idgames> mirror to use when downloading files requested by a
configuration file or by the user.

=cut

has q(default_mirror_uri)   => (
    is              => q(rw),
    isa             => q(Str),
    default         => q(),
    documentation   =>
          qq|# option: default_mirror_uri\n|
        . qq(# value\(s\): [http|ftp|file]://host:port/path/\n)
        . qq|# default: (empty)\n|
        . qq|# example: default_mirror_uri |
        . qq|= ftp://ftp.fu-berlin.de/pc/games/idgames/\n|
        . qq|# URI to use to download content from an idgames mirror\n|
); # has q(default_mirror_uri)

=head2 listen_port

Port number to listen to for connections by the worker and GUI threads.
Defaults to port C<6666> TCP.

=cut

has q(listen_port)   => (
    is              => q(ro),
    isa             => q(Int),
    default         => q(6666),
    documentation   =>
          qq|# option: listen_port\n|
        . qq|# value: an integer port number\n|
        . qq|# default: 6666\n|
        . qq|# example: listen_port = 6666\n|
        . qq|# listen on this port for connections from worker/gui threads\n|
); # has q(listen_port)

=head2 listen_address

IP address to listen to for connections by the worker and GUI threads.
Defaults to localhost (C<127.0.0.1>).

=cut

has q(listen_address)   => (
    is              => q(ro),
    isa             => q(Str),
    default         => q(127.0.0.1),
    documentation   =>
          qq|# option: listen_address\n|
        . qq|# value: a valid IPv4 IP address\n|
        . qq|# default: 127.0.0.1\n|
        . qq|# example: listen_address = 6666\n|
        . qq|# listen on this address for connections from worker/gui threads\n|
); # has q(listen_address)

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

# vim: filetype=perl shiftwidth=4 tabstop=4:
1; # End of App::Mayhem
