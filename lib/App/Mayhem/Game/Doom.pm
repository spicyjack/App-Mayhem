package App::Mayhem::Game::Doom;

use Mouse::Role; # sets strict and warnings

=head1 NAME

App::Mayhem::Games::Doom - A role that describes the game B<Doom>.

=head1 VERSION

Version 0.0.1

=cut

use version; our $VERSION = qv('0.0.1');

=head1 SYNOPSIS

A L<Mouse::Role> object that is used to describe abstract things about the
game B<Doom>.  This object cannot be created directly, but must be used with
the C<with> keyword to bring the role into the calling object.

    package App::Mayhem::Engine::SomeDoomEngine;

    use Mouse;
    with qw(App::Mayhem::Games::Doom);

=head1 REQUIRED OBJECT ATTRIBUTES

These object attributes are required to be implemented by any class that
consumes this role.

=cut

requires qw(
    engine_name
    engine_description
    engine_homepage_uri
    engine_provides
    binary_name
); # requires

=over

=item engine_name

The name of this Doom game engine.

=item engine_description

The description of this game engine.

=item engine_homepage_uri

The URI to the homepage for this engine.

=item engine_provides

Return a list of games that this game engine can play; for example, C<Doom>,
C<Heretic>, C<Hexen>, C<Strife>, etc.

=item binary_name

The name of the binary to execute in order to run the game.

=back

=head1 OBJECT METHODS

=head2 game_name()

Required arguments: none

Returns the name of this game, formatted for viewing by humans.

=cut

sub game_name {
    my $self = shift;
    return q(Doom);
} # sub game_name

=head2 game_description()

Required arguments: none

Returns the full description of this game.

=cut

sub game_description {
    my $self = shift;
    return <<'EOD';
(From http://doom.wikia.com/wiki/Doom);
Doom (officially cased DOOM) is the first release of the Doom series, and one
of the games that consolidated the first-person shooter genre. With a science
fiction and horror style, it gives the players the role of marines who find
themselves in the focal point of an invasion from hell. The game introduced
deathmatch and cooperative play in the explicit sense, and helped further the
practice of allowing and encouraging fan-made modifications of commercial video
games. It was first released on December 10, 1993, when a shareware copy was
uploaded to an FTP server at the University of Wisconsin.
EOD
} # sub game_name

=head1 OBJECT ATTRIBUTES

=head2 binary_path

The path to a binary file for a game engine.  Each engine module will only
know about one binary per module.

=cut

has q(binary_path)  => (
    is              => q(rw),
    isa             => q(Str),
); # has q(binary_path)

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

    perldoc App::Mayhem::Game::Doom

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

1; # End of App::Mayhem::Game::Doom
