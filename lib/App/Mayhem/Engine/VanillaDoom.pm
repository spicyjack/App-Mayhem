package App::Mayhem::Engine::VanillaDoom;

=head1 NAME

App::Mayhem::Engine::VanillaDoom - Vanilla Doom options

=head1 VERSION

Version 0.0.4

=cut

use Mouse::Role; # sets strict and warnings
use version; our $VERSION = qv('0.0.4');

# pull in the utils class for things like lists of attributes and dumping
# documentation
# 06Apr2011 - I don't think you care about this in roles
#with qw(App::Mayhem::Utils);

=head1 SYNOPSIS

A module that abstracts command-line options for C<Vanilla Doom>, or "Doom as
id Software released it".  These options should be supported by most Doom
engines, which means that modules for each Doom engine need to consume this
role, and then add further engine-specific options and customizations.

    use App::Mayhem::Engine::SomeEngine;

    with qw(App::Mayhem::Engine::VanillaDoom);
    ...

=head1 OBJECT ATTRIBUTES

You can get an object's attribute by calling it's name as an object method.
You can set an object's attribute by passing a value while calling it's name
as an object method.

=head2 doom_client_path

Since some Doom source ports have separate client and server binaries, there
is separate attributes for them.  This attribute is for the path on the
filesystem to the Doom client binary (program).

=cut

has q(doom_client_path)   => (
    is              => q{rw},
    isa             => q{Str},
    documentation   =>
          qq{# option: doom_client_path\n}
        . qq{# value(s): /path/to/a/doom/client\n}
        . qq{# default: (empty)\n}
        . qq{# example: doom_client_path = /usr/games/doom-client\n}
        . qq{# Path to the client binary\n},
); # has q(doom_client_path)

=head2 doom_server_path

The path on the filesystem to the Doom server binary, if a server binary is
provided by the engine.

=cut

has q(doom_server_path)   => (
    is              => q{rw},
    isa             => q{Str},
    documentation   =>
          qq{# option: doom_server_path\n}
        . qq{# value(s): /path/to/a/doom/server\n}
        . qq{# default: (empty)\n}
        . qq{# example: doom_server_path = /usr/games/doom-server\n}
        . qq{# Path to the server binary\n},
); # has q(doom_server_path)

=head2 altdeath

Alternate deathmatch mode, where items respawn after a certain amount of time
has passed since they were picked up.

=cut

has q(altdeath)     => (
    is              => q{rw},
    isa             => q{Bool},
    default         => 0,
    documentation   =>
          qq{# option: altdeath\n}
        . qq{# value(s): 0 = not enabled, 1 = enabled\n}
        . qq{# default: 0 (not enabled)\n}
        . qq{# example: altdeath = 1\n}
        . qq{# Enables alternate deathmatch mode (Deathmatch v2.0); items\n}
        . qq{# will respawn a short time after they have been picked up\n}
        . qq{# by the players\n},
); # has q(altdeath)

=head2 cdrom

Play from a CD-ROM using the files in C<C:\doomdata>.  This is a
DOS/Windows-specific option.

=cut

has q(cdrom)        => (
    is              => q{rw},
    isa             => q{Bool},
    default         => 0,
    documentation   =>
          qq{# option: cdrom\n}
        . qq{# value(s): 0 = not enabled, 1 = enabled\n}
        . qq{# default: 0 (not enabled)\n}
        . qq{# example: cdrom = 1\n}
        .  q{# Play from a CD-ROM drive, using files in C:\doomdata} . qq{\n}
        . qq{# Option only works on Windows machines\n},
); # has q(cdrom)

=head2 config

The full path to a Doom configuration file.

=cut

has q(config)       => (
    is              => q{rw},
    isa             => q{Str},
    documentation   =>
          qq{# option: config\n}
        . qq{# value(s): a system filepath\n}
        . qq{# default: (empty)\n}
        . qq{# example: config = /path/to/a/config/file.cfg\n}
        . qq{# Full path to a Doom configuration file\n},
); # has q(config)

=head2 deathmatch

Play Doom using 'deathmatch' mode, meaning player-versus-player.  Note that
items will not respawn in this mode.

=cut

has q(deathmatch)   => (
    is              => q{rw},
    isa             => q{Bool},
    default         => 0,
    documentation   =>
          qq{# option: deathmatch\n}
        . qq{# value(s): 0 = not enabled, 1 = enabled\n}
        . qq{# default: 0 (not enabled)\n}
        . qq{# example: deathmatch = 1\n}
        . qq{# Deathmatch mode (v1.0); note that items do not respawn\n}
        . qq{# in this mode\n},
); # has q(deathmatch)

=head2 devparm

Developer's parameter, which runs the game in developer mode
L<http://doom.wikia.com/wiki/Developer_mode>, creating screenshots with the
C<F1> key and showing the tics-per-frame meter on the lower left of the
screen.

=cut

has q(devparm)   => (
    is              => q{rw},
    isa             => q{Bool},
    default         => 0,
    documentation   =>
          qq{# option: devparm\n}
        . qq{# value(s): 0 = not enabled, 1 = enabled\n}
        . qq{# default: 0 (not enabled)\n}
        . qq{# example: devparm = 1\n}
        . qq{# Developer's parameter, runs game in developer mode\n},
); # has q(devparm)

=head2 fast

Fast monsters; monsters will be faster and attack more often.   Needs to be
used with C<warp> to be effective.

=cut

has q(fast)   => (
    is              => q{rw},
    isa             => q{Bool},
    default         => 0,
    documentation   =>
          qq{# option: fast\n}
        . qq{# value(s): 0 = not enabled, 1 = enabled\n}
        . qq{# default: 0 (not enabled)\n}
        . qq{# example: fast = 1\n}
        . qq{# Fast monsters; needs 'warp' to be effective\n},
); # has q(fast)

=head2 file

Load additional WAD files and lumps.  Multiple files can be specified with
multiple C<-file> arguments, or one C<-file> argument with multiple WAD files
separated by spaces depending on the engine.

=cut

has q(file)   => (
    is              => q{rw},
    isa             => q{Str},
    documentation   =>
          qq{# option: file\n}
        . qq{# value(s): a path to one or more files on the filesystem\n}
        . qq{# default: (empty)\n}
        . qq{# example: file /path/to/file1 /path/to/file2}
        . qq{# Path to extra PWADs\n},
); # has q(file)

=head2 nomonsters

No monsters; no monsters will be spawned.  Needs to be used with C<warp> to be
effective.

=cut

has q(nomonsters)   => (
    is              => q{rw},
    isa             => q{Bool},
    default         => 0,
    documentation   =>
          qq{# option: nomonsters\n}
        . qq{# value(s): 0 = not enabled, 1 = enabled\n}
        . qq{# default: 0 (not enabled)\n}
        . qq{# example: nomonsters = 1\n}
        . qq{# Monsters won't spawn; needs 'warp' to be effective\n},
); # has q(nomonsters)

=head2 respawn

Respawn monsters.  Monsters will be re-spawned after they are killed.  Needs
to be used with C<warp> to be effective.

=cut

has q(respawn)   => (
    is              => q{rw},
    isa             => q{Bool},
    default         => 0,
    documentation   =>
          qq{# option: respawn\n}
        . qq{# value(s): 0 = not enabled, 1 = enabled\n}
        . qq{# default: 0 (not enabled)\n}
        . qq{# example: respawn = 1\n}
        . qq{# Monsters re-spawn after dying; needs 'warp' to be effective\n},
); # has q(respawn)

=head2 skill

Skill level to start the game with.

=cut

has q(skill)   => (
    is              => q{rw},
    isa             => q{Int},
    documentation   =>
          qq{# option: skill\n}
        . qq{# value(s): Integer between 0 (no monsters/objects) and 5 (hard)\n}
        . qq{# default: (selected ingame)\n}
        . qq{# example: skill 3\n}
        . qq{# Skill level to start the game with.\n},
); # has q(skill)

=head2 warp

Warp to the level requested, skipping the title screen and demo sequence.  For
Doom I games, an episode number and map number must be specified.  For Doom II
games, only the map number (between [0]1 and 32) must be specified.

=cut

has q(warp)   => (
    is              => q{rw},
    isa             => q{Str},
    documentation   =>
          qq{# option: warp\n}
        . qq{# value(s): the level to warp to once the game loads\n}
        . qq{# default: (selected ingame)\n}
        . qq{# example: warp 3 5 (Doom I) warp 29 (Doom II)\n}
        . qq{# Warp to this level after the game initally loads\n},
); # has q(file)


=head1 OBJECT METHODS

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

1; # End of App::Mayhem::Engine::VanillaDoom
