#!/usr/bin/env perl 

# external packages
use Getopt::Long;
use Log::Log4perl qw(get_logger :levels);
use Mouse; # sets strict and warnings
# we need to initialize Gtk2 here on Mac OS X
# You can't have a library that's linked to the CoreFramework start in a
# child thread.  http://bugs.python.org/issue7085 explains the problem
use Gtk2 qw(-init -threads-init);

=head1 NAME

mayhem.pl - The Mayhem Launcher - a launcher for classic shooters

=head1 VERSION

Version v0.0.2

=cut

use version; our $VERSION = qv('0.0.2');

=head1 SYNOPSIS

A launcher of classic first-person shooters (FPS).

    perl mayhem.pl

Creates an instance of the L<App::Mayhem> class and transfers control to it,
thereby causing the Mayhem GTK2 launcher to run.

Script normally exits with a 0 status code once the user exits the GUI.

=cut

use App::Mayhem;

my $mayhem = App::Mayhem->new();
$mayhem->run();
#exit 0;

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

Copyright 2010-2011 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::Mayhem
