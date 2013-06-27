package App::Mayhem::Roles::Meta;

use Cwd qw(abs_path);
use Log::Log4perl qw(:levels :no_extra_logdie_message);
use Mouse::Role; # sets strict and warnings
use POSIX qw(strftime); # strftime function

use constant {
    LOGNAME => q(Meta),
};

=head1 NAME

App::Mayhem::Roles::Meta - A module for Mayhem metadata.

=head1 VERSION

Version 0.0.1

=cut

use version; our $VERSION = qv('0.0.1');

=head1 SYNOPSIS

A place to store metadata for the Mayhem launcher.  Metadata would include
L<Gtk2::Builder> XML files, image files used in Mayhem dialogs, and GTK
configuration files.

    package MyPackage;

    use Mouse;
    with q(App::Mayhem::Roles::Meta);

=head1 OBJECT RESOURCES

This object can return the absolute path on the filesystem to a specific file.
Use the L<meta_get_resource_path()> method to get the path to the file, or the
L<load_resource()> method to read the file from the filesystem.

The following resources are known by this module:

=cut

my %_resources = (
    img_configure_button    => q(configure.16x16.png),
    file_gtkrc              => q(gtkrc.Nodoka-Fuego),
    img_logo_300x72         => q(mayhem-logo.neon.orange-300x72.jpg),
    img_logo_500x109        => q(mayhem-logo.neon.orange-500x109.jpg),
    img_logo_text           => q(mayhem-logo.text.neon.orange-300x75.jpg),
    img_left_sidebar        => q(mohawkb-skinny-150x234.jpg),
    layout_compact          => q(mayhem_compact_layout.glade),
    layout_larger           => q(mayhem_larger_layout.glade),
    layout_splashscreen     => q(mayhem_splashscreen.glade),
);

=over

=item img_configure_button    => q(configure.16x16.png)

=item file_gtkrc              => q(gtkrc.Nodoka-Fuego)

=item img_logo_300x72         => q(mayhem-logo.neon.orange-300x72.jpg)

=item img_logo_500x109        => q(mayhem-logo.neon.orange-500x109.jpg)

=item img_logo_text           => q(mayhem-logo.text.neon.orange-300x75.jpg)

=item img_left_sidebar        => q(mohawkb-skinny-150x234.jpg)

=item layout_compact          => q(mayhem_compact_layout.glade)

=item layout_larger           => q(mayhem_larger_layout.glade)

=item layout_splashscreen     => q(mayhem_splashscreen.glade)

=back

The following paths will be used to search for game engine binaries:

=cut

my @_search_paths = qw(
    /usr/games
    /usr/local/games
    /usr/bin
    /usr/local/bin
); # @search_paths

=over

=item /usr/games

=item /usr/local/games

=item /usr/bin

=item /usr/local/bin

=back

Other paths can be specified in the configuration file.

=head1 OBJECT METHODS

=head2 get_meta_dir()

Required arguments: None

Returns the directory where the L<App::Mayhem::Roles::Meta> module is located
on the filesystem.  This directory can be used to find other modules in the
L<App::Mayhem> directory structure.

=cut

sub get_meta_dir {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    my $meta_dir = $self->get_mayhem_base_dir() . q(/App/Mayhem/Roles/Meta);
    $log->debug(LOGNAME . q(: Meta.pm located at:));
    $log->debug(LOGNAME . q(: ) . $self->truncate(string => $meta_dir) );
    return $meta_dir;
} # sub get_meta_dir

=head2 meta_get_search_paths()

Required arguments: None

Returns a list of paths to search for binaries.

=cut

sub meta_get_search_paths {
    return @_search_paths;
} # sub meta_get_search_paths

=head2 meta_get_resource_path()

Required arguments: The name of the resource to return

Returns an absolute path to a resource on the filesystem, usually a file of
some kind.  Returns C<undef> if the resource does not exist in this object.

=cut

sub meta_get_resource_path {
    my $self = shift;
    my $resource = shift;
    my $log = Log::Log4perl->get_logger();

    my $meta_dir = $self->get_meta_dir();

    # see if $resource exists in the resources hash
    if ( exists $_resources{$resource} ) {
        my $file = $_resources{$resource};
        # verify the resource exists at it's full path, then return it
        if ( -e $meta_dir . q(/) . $file ) {
            $log->debug(LOGNAME . qq(: resource $resource requested;));
            $log->debug(LOGNAME . qq(: full path to resource $resource is:));
            $log->debug(LOGNAME . q(: )
                . $self->truncate( string => $meta_dir . q(/) . $file) );
            return $meta_dir . q(/) . $file;
        } else {
            $log->warn(LOGNAME
                . qq(: resource $resource requested, does not exist));
            $log->debug(LOGNAME . q(: checked: ) . $meta_dir . q(/) . $file);
            return undef;
        } # if ( -e $meta_dir . q(/) . $file )
    } else {
        $log->warn(LOGNAME . q(: Invalid resource requested: ) . $resource);
        return undef;
    } # if ( exists $_resources{$resource} )
} # sub blank_method

=head2 meta_load_resource()

Required arguments:

=over

=item $resource

Name of the resource to read in from the filesystem.

=back

Returns the contents of the resource as a scalar.  Using the C<$resource>
requested, calls L<App::Mayhem::Roles::Meta::meta_get_resource_path()> to
resolve the filename of the resource, and then it is read in.

=cut

sub meta_load_resource {
    my $self = shift;
    my $resource = shift;
    my $log = Log::Log4perl->get_logger();

    my $resource_path = $self->meta_get_resource_path($resource);
    if ( defined $resource_path ) {
        $log->debug(LOGNAME . qq(: Loading resource:));
        $log->debug(q( - ) . $self->truncate( string => $resource_path));
        local $/;
        open(my $fh, '<', $resource_path)
            or $log->die(LOGNAME . qq(: Can't open $resource_path : $!"));
        my $resource_string = <$fh>;
        return $resource_string;
    } else {
        return undef;
    } # if ( defined $resource_path )
} # sub load_resource

=head2 meta_load_gtkrc()

Required arguments: None

Loads the C<.gtkrc-2.0> for Mayhem.  Always returns C<undef>.

=cut

sub meta_load_gtkrc {
    my $self = shift;
    my $gtkrc = shift;
    my $log = Log::Log4perl->get_logger();

    #Gtk2::Rc->parse_string($gtkrc);
    $log->debug(LOGNAME . qq(: meta_load_gtkrc: Parsing gtkrc file $gtkrc));
    Gtk2::Rc->parse($gtkrc);
    return undef;
} # sub load_gtkrc

##################################################
# App::Mayhem->meta_get_nonrunnable_engines_list #
##################################################

=head2 meta_get_nonrunnable_engines_list()

Required arguments: None

Returns a list of engines that cannot be "run", i.e. roles that are consumed
by other engine objects.  This list of engines is maintained inside this
module.

=cut

sub meta_get_nonrunnable_engines_list {
    return qw(App::Mayhem::Engine::VanillaDoom);
}

###############################################
# App::Mayhem->meta_get_runnable_engines_list #
###############################################

=head2 meta_get_runnable_engines_list()

Required arguments: None

Returns a list of engines that can be "run", i.e. those objects can be
created, because the object describes an engine that exists on the filesystem.

=cut

sub meta_get_runnable_engines_list {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: Entering ->meta_get_runnable_engines_list));
    my @non_runnable_engines = $self->meta_get_nonrunnable_engines_list();

    my @engines = $self->meta_get_all_engines_list();

    my @runnable_engines;
    foreach my $engine ( @engines ) {
        if ( scalar(grep(/$engine/, @non_runnable_engines)) == 0 ) {
            push(@runnable_engines, $engine);
        }
    }
    $log->debug(LOGNAME . q(: meta_get_runnable_engines_list: returning )
        . scalar(@runnable_engines) . q( engines));
    return @runnable_engines;
}

##########################################
# App::Mayhem->meta_get_all_engines_list #
##########################################

=head2 meta_get_all_engines_list()

Required arguments: None

Returns a list of engines found in the C<Engine> directory of the Mayhem
distribution.  This list may include engines that cannot be run directly,
because they are "roles", or object that are meant to be used by other Engine
objects.

=cut

sub meta_get_all_engines_list {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: Entering ->meta_get_all_engines_list));
    my $rule = File::Find::Rule->file()->name('*.pm');
    # grab the path to this file, use it as a base for searching for more
    # modules
    my $search_dir = $self->get_mayhem_base_dir();
    $log->debug(LOGNAME .
        qq(: meta_get_all_engines_list: search dіrectory:));
    $log->debug(q( - ) . $self->truncate(string => $search_dir));
    # go over each test file found and eval it
    my @found_modules;
    foreach my $module ( sort($rule->in(qq($search_dir/App/Mayhem/Engine))) ) {
        $module =~ s/^.+(App\/Mayhem.+)\.pm$/$1/g;
        $module = $1;
        $module =~ s!/!::!g;
        $log->debug(LOGNAME
            . qq(: Found module $module));
        push(@found_modules, $module);
    } # foreach my $file ( sort($rule->in($search_dir)) )
    $log->debug(LOGNAME . q(: meta_get_all_engines_list: returning )
        . scalar(@found_modules) . q( engines));
    return sort(@found_modules);
} # sub _get_engines_list

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

1; # End of App::Mayhem::Roles::Meta
