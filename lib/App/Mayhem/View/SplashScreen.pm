package App::Mayhem::View::SplashScreen;

# FIXME
# - diagram the call flows between this module and the controller in wiki
# syntax for exporting to Google Code's wiki

use Log::Log4perl qw(:levels);

use Mouse; # sets strict and warnings
use POSIX qw(strftime); # strftime function
# http://gtk2-perl.sourceforge.net/doc/pod/Gtk2.html
use Gtk2 qw(-init -threads-init);
use Glib qw{TRUE FALSE};

use constant {
    LOGNAME     => q(Splash),
    API_VERSION => 1,
};

# Mouse roles that this module consumes
with qw(
    App::Mayhem::Utils
    App::Mayhem::Roles::Meta
); # with

=head1 NAME

App::Mayhem::View::SplashScreen - The splash screen that's displayed when
Mayhem is launched.

=head1 VERSION

Version 0.0.3

=cut

use version; our $VERSION = qv('0.0.3');

=head1 SYNOPSIS

Display a splash screen when requested to do so by the controller.

    package MyPackage;

    use Mouse;
    use App::Mayhem::View::SplashScreen;
    my $splash = App::Mayhem::View::SplashScreen->new();

=head1 OBJECT METHODS

=head2 new()

Optional/Required arguments: None.

Creates a splashscreen dialog, which allows for callbacks from the controller
object as far as module loading/script configuration status updates to the end
user.

=cut

##########################################
# App::Mayhem::View::SplashScreen->BUILD #
##########################################
sub BUILD {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: Entering -> BUILD));
    #load UI from a text string
    #Gtk2::Rc->parse_string($self->load_resource(q(file_gtkrc)));
    #$self->load_gtkrc($self->load_resource(q(file_gtkrc)) );
    #$self->load_gtkrc($self->get_resource_path(q(file_gtkrc)) );

    $log->debug(LOGNAME . q(: Setting up Gtk2::Builder object and resources));
    my $builder = Gtk2::Builder->new();
    # save the builder so other methods can use it
    $self->_builder($builder);
    # load the builder file
    $log->debug(LOGNAME . q(: loading resource 'layout_splashscreen'));
    $builder->add_from_string(
        $self->meta_load_resource(q(layout_splashscreen)));

    # grab all of the controls that we will want to modify later; make sure
    # that we have valid controls though
    my $toplevel = $builder->get_object(q(toplevel));
    $toplevel->signal_connect(destroy => sub {Gtk2->main_quit});

    # don't trust Gtk2::Builder to be able to find the image files;
    # load them by hand
    my $img_splash = $builder->get_object(q(img_splash));
    $log->debug(LOGNAME . q(: loading resource 'img_logo_500x109'));
    $img_splash->set_from_file(
        $self->meta_get_resource_path(q(img_logo_500x109)));

    # set up some gunk for the status bar
    my $release_version = $App::Mayhem::RELEASE_VERSION || qq(Unknown);
    my $release_date = $App::Mayhem::RELEASE_DATE || qq(Unknown date);
    my $lbl_substatus = $builder->get_object(q(lbl_substatus));
    $lbl_substatus->set_text(
        qq{Mayhem Launcher, version $release_version ($release_date)});

    # progress bar for the splash screen
    my $progress = $builder->get_object(q(progress_splash));
    $progress->set_orientation(q(left-to-right));
    $progress->set_text(q(Initializing...));

    $self->_print_socket(q(get_max_progress_value));

    # pass control to GTK MainLoop
    Gtk2->main();
} # sub BUILD

=head2 set_max_progress_value()

Required arguments:

=over

=item max_progress_value => ?

Number of progress updates that will to be sent by the controller.  This lets
the splashscreen set up the progress bar control correctly.  A progress update
would be sent when a new module is initialized.

=back

Set the maximum size of the progress bar, or how many items of progress need
to be updated by the controller.

=cut

###########################################################
# App::Mayhem::View::SplashScreen->set_max_progress_value #
###########################################################
sub set_max_progress_value {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: Entering ->set_max_progress_value));
    $log->logdie( LOGNAME . qq(: set_max_progress_value method )
        . q(needs a command argument!) )
        unless ( exists($args{command_args}) );

    $log->logdie( LOGNAME . qq(: set_max_progress_value method )
        . q(needs a socket_obj argument!) )
        unless ( exists($args{socket_obj}) );

    my $max_progress_value = $args{command_args};
    ## ACK
    $self->_print_client_socket(
        message     => q(OK set_max_progress_value),
        socket_obj  => $args{socket_obj},
    );

    # grab the builder object so we can work on the status bar
    my $builder = $self->_builder();
    my $toplevel = $builder->get_object(q(toplevel));

    $self->_max_progress_value($max_progress_value + 1);

    # display the main window
    $toplevel->show_all();

    sleep 3;
    # start the engine initialization process
    return q(init_all_engines);
} # sub set_max_progress_value

=head2 bump_progress()

Optional arguments:

=over

=item text => q(Text Message)

=back

Bump the progress bar.  Displays the text message in the progress bar if a
C<text> parameter is passed in.

=cut

##################################################
# App::Mayhem::View::SplashScreen->bump_progress #
##################################################
sub bump_progress {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: Entering ->bump_progress));
    $log->logdie(LOGNAME . qq(: bump_progress )
        . q(needs a socket_obj argument!) )
        unless ( exists($args{socket_obj}) );
    $log->logdie(LOGNAME . qq(: bump_progress )
        . q(needs a command_args argument!) )
        unless ( exists($args{command_args}) );

    ## ACK
    $self->_print_client_socket(
        message     => q(OK bump_progress),
        socket_obj  => $args{socket_obj},
    );

    my $progress_text = $args{command_args};
    my $builder = $self->_builder();
    my $max_progress_val = $self->_max_progress_value();
    my $current_progress_val = $self->_current_progress();
    $current_progress_val++;
    $log->debug(LOGNAME . q(: current progress: )
        . qq|$current_progress_val (max: $max_progress_val)|
    );
    my $progress = $builder->get_object(q(progress_splash));
    $progress->set_fraction( $current_progress_val/$max_progress_val );
    if ( defined $progress_text ) {
        $progress->set_text($progress_text);
    } # if ( defined $progress_text )
    $self->_current_progress($current_progress_val);
    # return undef so we don't send a reply to the remote socket
    return undef;
} # sub bump_progress

=head2 update_status()

Required arguments:

=over

=item $update_message

A message to display in the progress bar.

=back

Displays a message in the status bar.  This method is meant to be used by the
controller to update the user of the status of loading the game engines.

=cut

##################################################
# App::Mayhem::View::SplashScreen->update_status #
##################################################
sub update_status {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: Entering ->update_status));
    $log->logdie(LOGNAME . qq(: bump_progress )
        . q(needs a socket_obj argument!) )
        unless ( exists($args{socket_obj}) );
    $log->logdie(LOGNAME . qq(: bump_progress )
        . q(needs a command_args argument!) )
        unless ( exists($args{command_args}) );
    my $update_message = $args{command_args};

    ## ACK
    $self->_print_client_socket(
        message     => q(OK update_status),
        socket_obj  => $args{socket_obj},
    );

    my $builder = $self->_builder();
    my $progress = $builder->get_object(q(progress_splash));
    $progress->set_text($update_message);
    # return undef so we don't send a reply to the remote socket
    return undef;
}

=head2 init_complete()

Required/Optional arguments: None.

Display the message "Initialization is Complete", then wait for the exit
message from the controller.

=cut

##################################################
# App::Mayhem::View::SplashScreen->init_complete #
##################################################
sub init_complete {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    $log->debug(q(Splash: Entering ->init_complete));
    ## ACK
    $self->_print_client_socket(
        message     => q(OK init_complete),
        socket_obj  => $args{socket_obj},
    );

    my $builder = $self->_builder();
    my $toplevel = $builder->get_object(q(toplevel));

    my $max_progress_val = $self->_max_progress_value();
    my $current_progress_val = $self->_current_progress();
    # one final bump
    $current_progress_val++;
    $log->debug(q(Splash: init complete, progress: )
        . qq|$current_progress_val (max: $max_progress_val)|
    );
    my $progress = $builder->get_object(q(progress_splash));
    $progress->set_fraction( $current_progress_val/$max_progress_val );
    $progress->set_text(q(Initialization Complete!));
    # return undef so we don't send a reply to the remote socket

    # set a timer that destroys the splashscreen window
    Glib::Timeout->add(2000, sub { $toplevel->destroy(); return FALSE; });
    # FIXME close the socket, the MainMenu should open a new socket?
    return q(mayhem_event splashscreen_exit);
}

=head1 OBJECT ATTRIBUTES

=head2 _max_progress_value

The size of the progress bar, i.e. how many status messages need tobe
displayed by the progress bar during initialization.

=cut

has q(_max_progress_value) => (
    is              => q(rw),
    isa             => q(Int),
    default         => 0,
);

=head2 _current_progress

The current progress.  Updated via the C<_bump_progress> method.

=cut

has q(_current_progress) => (
    is              => q(rw),
    isa             => q(Int),
    default         => 0,
);

=head2 _builder

A copy of the L<Gtk2::Builder> object used to create the GUI.

=cut

has q(_builder) => (
    is              => q(rw),
    isa             => q(Object),
);

=head2 _manager

The GUI manager object, which handles socket communications with the
controller.

=cut

has q(_manager) => (
    is              => q(rw),
    isa             => q(Object),
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

1; # End of App::Mayhem::View::SplashScreen
