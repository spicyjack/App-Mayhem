package App::Mayhem::Engine::PrBoom;

use Mouse; # sets strict and warnings
with qw(
    App::Mayhem::Game::Doom
    App::Mayhem::Engine::VanillaDoom
    App::Mayhem::Meta
); # with

=head1 NAME

App::Mayhem::Engines::PrBoom - A module that wraps the C<Chocolate
Doom> Doom game engine.

=head1 VERSION

Version 0.0.2

=cut

use version; our $VERSION = qv('0.0.2');

=head1 SYNOPSIS

The B<Chocolate Doom> Doom engine, an engine for the game B<Doom>.

    use App::Mayhem::Engine::PrBoom;
    my $engine = App::Mayhem::Engine::PrBoom->new();
    print $engine->engine_name();

=head1 OBJECT METHODS

=head2 new

Creates a Chocolate Doom engine object, returns it to the caller.  During
iniitalization, checks are performed in order to verify that the binary
specified by the attribute C<binary_name> can be found on the filesystem.

Returns a L<App::Mayhem::Engine::PrBoom> object.  Use the
C<is_available()> method to determine if this engine can actually be used to
run games with.

=cut

sub BUILD {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    my @search_paths = $self->meta_get_search_paths();
    my $binary_path;
    foreach my $path ( @search_paths ) {
        if ( -x $path . q(/) . $self->binary_name() ) {
            $self->binary_path($path . q(/) . $self->binary_name());
            $log->debug(qq(PrBoom: found prboom binary at:)
                . $self->binary_path() );
        } # if ( -x $path . q(/) . $self->binary_name() )
    } # foreach my $path
    return $self;
}

=head2 is_available()

Returns true (1) if the engine is available (the C<binary_name> was found in
one of the C<binary_paths>), or false (0) if the engine is not available.
Basically, this is a nice wrapper around C<$self->binary_path()>.

=cut

sub is_available {
    my $self = shift;

    if ( defined $self->binary_path() ) {
        return 1;
    } else {
        return 0;
    } # if ( defined $self->binary_path() )
}

=head2 engine_name()

Returns the name of this engine, suitable for outputting to end-users.

=cut

sub engine_name {
    return q(PrBoom);
}

=head2 engine_description()

Returns the description for this engine, suitable for outputting to end-users.

=cut

sub engine_description {
    return <<DESC
PrBoom, originally short for "Proff Boom", is a source port for Windows,
Linux/POSIX, OpenVMS and Mac OS X based initially on Boom, but later merged
with LxDoom and LsdlDoom. As a result of this merger, PrBoom is compatible
with both Boom and MBF. It includes OpenGL features for the renderer (as
GLBoom) as well as some enhancements over the engines it is based on, such as
being able to handle levels with twice as many segs, vertices and sidedefs
than usual. In addition to the code from its predecessors, it incorporates
bits of code from the Eternity Engine, and PrBoom+.
DESC
}

=head2 engine_homepage_uri()

Returns the homepage URI for this engine, suitable for outputting to end-users.

=cut

sub engine_homepage_uri {
    return q(http://prboom.sourceforge.net/);
}

=head2 engine_provides()

Returns a list of games that this engine can play; currently only Doom.

=cut

sub engine_provides {
    return ( q(Doom) );
}

=head2 binary_name()

The name of the binary to execute in order to run the game.

=cut

sub binary_name {
    return q(prboom);
}

=head1 OBJECT ATTRIBUTES

=head2 config_block_header

The text used for the configuration block header in a configuration file.

=cut

has q(config_block_header)   => (
    is              => q(ro),
    isa             => q(Str),
    default         => qq([PrBoom]),
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

1; # End of App::Mayhem::Engines::PrBoom
