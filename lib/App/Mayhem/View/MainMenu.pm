package App::Mayhem::View::MainMenu;

use Log::Log4perl qw(get_logger :levels);
use Mouse; # sets strict and warnings
use POSIX qw(strftime); # strftime function
# http://gtk2-perl.sourceforge.net/doc/pod/Gtk2.html
use Gtk2 qw(-init -threads-init);
use Glib qw{TRUE FALSE};

# mouse
with qw(
    App::Mayhem::Utils
    App::Mayhem::Roles::Meta
);

use constant {
    # for libgtk
    ID_COLUMN       => 0,
    LOGNAME         => q(MainMenu),
}; # use constant

=head1 NAME

App::Mayhem::View::MainMenu - The splash screen that's displayed when
Mayhem is launched.

=head1 VERSION

Version 0.0.2

=cut

use version; our $VERSION = qv('0.0.2');

=head1 SYNOPSIS

A blank module to be used as a template stub for new modules.  This module
should just "do the needful".

    package MyPackage;

    use Mouse;
    extends 'App::Mayhem::View::MainMenu';

=head1 OBJECT METHODS

=head2 new()

Optional arguments:

=over

=item $compact => [0|1]

A key/value pair representing whether or not to display the main menu with the
larger layout or the compact layout.  A C<0> or C<undef> will display the
larger layout, and any other value will display the compact layout.

=back

Creates the GUI object, loads the L<Gtk2> module, and displays a dialog.
Returns C<undef>.

=cut

##########################################
# App::Mayhem::View::MainMenu::BUILD #
##########################################

sub BUILD {
    my $self = shift;
    my $log = get_logger();

    $log->debug(q(Entering App::Mayhem::View::MainMenu::BUILD));
    my @games = (
        q(Doom),
        q(Quake),
        q(Duke Nukem 3D),
        q(Descent),
    ); # my @games

    my @engines = (
        q(Chocolate Doom),
        q(Doom Legacy),
        q(DENG - Doomsday Engine),
        q(EDGE - Enhanced Doom Game Engine),
        q(Eternity Engine),
        q(Odamex),
        q(PrBoom),
        q(PrBoom+),
        q(ReMooD),
        q(Vavoom),
        q(ZDoom),
    ); # @engines

    my @profiles = (
        q(No Profile),
        q(Profile #1),
        q(Profile #2),
        q(Profile #3),
        q(Profile #4),
    ); # @profiles

    #load UI from a text string
    #Gtk2::Rc->parse_string($self->load_resource(q(file_gtkrc)));
    #$self->load_gtkrc($self->load_resource(q(file_gtkrc)) );
    #$self->load_gtkrc($self->meta_get_resource_path(q(file_gtkrc)) );

    my $builder = Gtk2::Builder->new();
    # load the builder file
    if ( $self->compact() ) {
        $builder->add_from_string($self->meta_load_resource(q(layout_compact)));
    } else {
        $builder->add_from_string($self->meta_load_resource(q(layout_larger)));
    } # if ( $compact_layout )

    # grab all of the controls that we will want to modify later; make sure
    # that we have valid controls though
    my $toplevel = $builder->get_object(q(toplevel));

    # don't trust Gtk2::Builder to be able to find the image files;
    # load them by hand
    # mushroom cloud; not used in the compact layout
    if ( ! $self->compact() ) {
        my $img_mushroom = $builder->get_object(q(img_mushroom));
        $img_mushroom->set_from_file(
            $self->meta_get_resource_path(q(img_left_sidebar)) );
        # text logo
        my $img_mayhem_logo = $builder->get_object(q(img_mayhem_logo));
        $img_mayhem_logo->set_from_file(
            $self->meta_get_resource_path(q(img_logo_text)) );
    } else {
        my $img_mayhem_logo = $builder->get_object(q(img_mayhem_logo));
        $img_mayhem_logo->set_from_file(
            $self->meta_get_resource_path(q(img_logo_300x72)) );
    } # if ( ! $self->compact() )
    # the configure buttons
    my $img_profile_cfg = $builder->get_object(q(img_profile_cfg));
    $img_profile_cfg->set_from_file(
        $self->meta_get_resource_path(q(img_configure_button)));
    my $img_game_cfg = $builder->get_object(q(img_game_cfg));
    $img_game_cfg->set_from_file(
        $self->meta_get_resource_path(q(img_configure_button)));
    my $img_engine_cfg = $builder->get_object(q(img_engine_cfg));
    $img_engine_cfg->set_from_file(
        $self->meta_get_resource_path(q(img_configure_button)));

    # set up the information stores
    # doom engines
    my $engines_store = Gtk2::ListStore->new(qw(Glib::String));
    foreach my $engine ( @engines ) {
        $engines_store->set($engines_store->append(), ID_COLUMN, $engine);
    } # foreach my $engine ( @engines )

    # doom wads
    my $game_store = Gtk2::ListStore->new(qw(Glib::String));
    foreach my $game ( @games ) {
        $game_store->set($game_store->append(), ID_COLUMN, $game);
    } # foreach my $game ( @games )

    # profiles
    my $profiles_store = Gtk2::ListStore->new(qw(Glib::String));
    foreach my $profile ( @profiles ) {
        $profiles_store->set($profiles_store->append(), ID_COLUMN, $profile);
    } # foreach my $profile ( @profiles )

    # see http://gtk2-perl.sourceforge.net/doc/pod/Gtk2/ComboBox.html
    # for a full explanation of how to create a ComboBox using a renderer

    # a renderer for text in cells, needed for the combo boxes below
    my $renderer = Gtk2::CellRendererText->new();

    # profiles combo box
    my $cbo_profile = $builder->get_object(q(cbo_profile));
    $cbo_profile->pack_start($renderer, TRUE);
    $cbo_profile->add_attribute($renderer, q(text) => ID_COLUMN);
    $cbo_profile->set_model($profiles_store);
    $cbo_profile->set_active(0);

    # game combo box
    my $cbo_game = $builder->get_object(q(cbo_game));
    $cbo_game->pack_start($renderer, TRUE);
    $cbo_game->add_attribute($renderer, q(text) => ID_COLUMN);
    $cbo_game->set_model($game_store);
    $cbo_game->set_active(0);

    # engines combo box
    my $cbo_engine = $builder->get_object(q(cbo_engine));
    $cbo_engine->pack_start($renderer, TRUE);
    $cbo_engine->add_attribute($renderer, q(text) => ID_COLUMN);
    $cbo_engine->set_model($engines_store);
    $cbo_engine->set_active(0);

    # grab the statusbar object
    my $statusbar = $builder->get_object(q(statusbar));
    # the version number of this statusbar message
    my $id_version = $statusbar->get_context_id(q(script_version));
    my $release_version = $App::Mayhem::RELEASE_VERSION || qq(Unknown version);
    my $release_date = $App::Mayhem::RELEASE_DATE || qq(Unknown date);
    # set the statusbar message
    # the msg_id would be used to pop this message back off of the stack
    my $msg_id = $statusbar->push($id_version,
        qq{Mayhem Launcher, version $release_version ($release_date)});

    # the buttons at the bottom of the dialog
    my $quit_btn = $builder->get_object(q(quit));
    my $launch_btn = $builder->get_object(q(launch));
    # connect some signals
    # FIXME this should send something to the socket to make the controller
    # clean up and call exit(); exit shouldn't be called here :(
    $toplevel->signal_connect(destroy => sub {exit 0;});
    # but only if the controls are defined
    $quit_btn->signal_connect(clicked => sub {exit 0;});
    $launch_btn->signal_connect(clicked => sub {warn qq(LAUNCH!!!\n)});

    # display the main window
    $toplevel->show_all();

    # pass control to GTK MainLoop
    Gtk2->main();
} # sub BUILD

=head1 OBJECT ATTRIBUTES

=head2 compact

See the C<new()> method above for the purpose of this attribute.

=cut

has q(compact) => (isa => q(Bool), is => q(ro), required => 1);

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

Copyright 2010 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::Mayhem::View::MainMenu
