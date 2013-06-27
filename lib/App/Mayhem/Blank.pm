package App::Mayhem::Blank;

use Log::Log4perl qw(:levels);
use constant {
        LOGNAME => q(Blank),
};
use POSIX qw(strftime); # strftime function
use Mouse; # sets strict and warnings





=head1 NAME

App::Mayhem::Blank - A blank module used as a stub for new modules.

=head1 VERSION

Version 0.0.1

=cut

use version; our $VERSION = qv('0.0.1');

=head1 SYNOPSIS

A blank module to be used as a template stub for new modules.  This module
should just "do the needful".

    package MyPackage;

    use Mouse;
    extends 'App::Mayhem::Blank';

=head1 OBJECT METHODS

=head2 blank_method()

Required arguments:

=over

=item argument1

This argument has a purpose.

=back

This object method does something neat.  It returns something, maybe a list,
scalar or object.

=cut

sub blank_method {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    return undef;
} # sub blank_method

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

1; # End of App::Mayhem::Blank
