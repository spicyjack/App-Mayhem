package App::Mayhem::Utils;

use Cwd qw(abs_path);
use Log::Log4perl qw(:levels :no_extra_logdie_message);
use Mouse::Role; # sets strict and warnings
use POSIX qw(strftime); # strftime function

use constant {
    LOGNAME         => q(Utils),
    TRUNCATE_LENGTH => 52,
};

=head1 NAME

App::Mayhem::Utils - Utilities used with all Mayhem modules

=head1 VERSION

Version 0.0.4

=cut

use version; our $VERSION = qv('0.0.4');

=head1 SYNOPSIS

A module with utility/helper functions used with the Mayhem Launcher.  This
module is meant to be called from other modules.

    package App::Mayhem::Engine::SomeEngine;

    use Mouse;
    with qw(App::Mayhem::Utils);

=head1 OBJECT METHODS

=head2 truncate()

Required arguments:

=over

=item string => $string

The string to truncate

=back

Optional arguments:

=over

=item length => $length

Length to truncate the C<$string>.  Default is 55 characters.

=back

Truncates C<$string> to C<$length>, or to the default length if no length
argument is used.

=cut

##################################
# App::Mayhem::Utils->truncate() #
##################################
sub truncate {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    $log->logdie(LOGNAME . qq(: truncate needs a string argument!) )
        unless ( exists($args{string}) );

    my $truncate_length;
    if ( exists($args{length}) ) {
        $truncate_length = $args{length};
    } else {
        $truncate_length = TRUNCATE_LENGTH;
    }
    return q(...) . substr($args{string}, ($truncate_length * -1) );
} # sub truncate

=head2 get_mayhem_base_dir()

Required arguments: None

Returns the base directory for the L<App::Mayhem> application.  This would be
the directory where the C<App> is located on the filesystem.

=cut

#############################################
# App::Mayhem::Utils->get_mayhem_base_dir() #
#############################################
sub get_mayhem_base_dir {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    my $base_dir = abs_path(__FILE__);
    $base_dir =~ s!\/App\/Mayhem\/Utils\.pm!!;
    $log->debug(LOGNAME . qq(: Mayhem base directory is:));
    $log->debug(LOGNAME . qq(: $base_dir));
    return $base_dir;
}


##################################
# App::Mayhem::Utils->lazy_use() #
##################################

=head2 lazy_use()

Required arguments:

=over

=item $requested_module

A scalar variable containing the name of a Perl module to load, along with any
load arguments for that module.

=back

Returns true (C<1>) for success, and dies with an error on failure.

=cut

sub lazy_use {
    my $self = shift;
    my $requested_module = shift;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . qq(: Entering lazy_use: $requested_module));
    # need to mangle @INC a bit
    if ( ! defined $self->mayhem_base_dir() ) {
        # scrape the full path out of the environment so that it can be used
        # to load modules with
        $self->mayhem_base_dir( $self->get_mayhem_base_dir() );
    }
    $log->debug(LOGNAME . q(: ) . $self->mayhem_base_dir());
    unshift(@INC, $self->mayhem_base_dir() );
    #eval { require $requested_module; $requested_module->import(); };
    eval qq(require $requested_module;);
    if ( $@ ) {
        $log->logdie(LOGNAME . qq(: Loading of $requested_module failed; $@));
    } # if ( $@ )
}

#####################################
# App::Mayhem::Utils->lazy_object() #
#####################################

=head2 lazy_object()

Required arguments:

=over

=item $requested_module

A scalar variable containing the name of a Perl module to load and
instantiate.

=back

Returns the object upon success, and dies with an error upon failure.

=cut

sub lazy_object {
    my $self = shift;
    my $requested_module = shift;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . qq(: Entering lazy_object...));
    $log->debug(LOGNAME . qq(: Calling lazy_use on $requested_module));
    $self->lazy_use($requested_module);
    my $module = $requested_module->new();
    return $module;
}

############################################
# App::Mayhem::Utils->get_attribute_list() #
############################################

=head2 get_attribute_list()

Required arguments:

=over

=item @attributes

A list of attributes to return to the caller; an empty list will return all of
the attributes that belong to the object.  Attributes that are requested but
don't exist in the object are ignored.

=back

Returns a list of requested attributes, or all attrbutes if no array was
passed in; does some error checking to verify that the requested attribute
exists in this object.

=cut

sub get_attribute_list {
    my $self = shift;
    my @requested_params = @_;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: get_attribute_list: entering method));
    my $meta = $self->meta();
    my @unchecked_params;
    # if the user requests a list of parameters, return just that list;
    # otherwise, return all of the parameters that are available
    if ( scalar(@requested_params) == 0 ) {
        @unchecked_params = $meta->get_attribute_list();
    } else {
        @unchecked_params = @requested_params;
    } # if ( scalar(@requested_params) = 0 )
    my @return_params;
    foreach my $param ( @unchecked_params ) {
        if ( $meta->has_attribute($param) ) {
            push(@return_params, $param);
        } else {
            $log->info(LOGNAME
                . qq(: Parameter $param doesn't exist in this object));
        } # if ( $self->does($param) )
    } # foreach my $param ( @doom_params )
    return @return_params;
}

#####################################
# App::Mayhem::Utils->get_timestamp #
#####################################

=head2 get_timestamp()

Create a time/date stamp using L<POSIX::strftime> and return to the caller.

=cut

sub get_timestamp {
    my $self = shift;
    return POSIX::strftime( q(%c), localtime() );
}

##############################################
# App::Mayhem::Utils->get_commandline_args() #
##############################################

=head2 get_commandline_args([@attributes])

Parse all of the object attributes and return a scalar containing the
attributes of this object as a list of command line options to Doom (or a
source port).  If this method is passed a list of attributes to return,
it will return only that list of attributes.  If an attribute does not exist
in this object, it's discarded, and an error message is logged.

=cut

sub get_commandline_args {
    my $self = shift;
    my @requested_params = @_;
    my $log = Log::Log4perl->get_logger();

    $log->debug(LOGNAME . q(: get_commandline_args: entering method));
    # grab a copy of the metaobject for querying 'isa'
    my $meta = $self->meta();

    # grab a list of appropriate doom parameters (object attributes)
    my @doom_params = $self->get_attribute_list(@requested_params);

    my $command_line;
    # we should either have a valid list of params (thanks to
    # _get_attribute_list above), or nothing, in which case this loop is
    # skipped
    foreach my $param ( sort(@doom_params) ) {
        $log->debug(LOGNAME . qq(: checking parameter $param));
        # grab the meta-information for this attribute
        my $attr = $meta->get_attribute($param);
        # get the 'isa' that this attribute was defined with‥
        $command_line .= $self->_parse_attribute(
            parse_type      => q(cmdline),
            parameter       => $param,
            attribute_type  => $attr->{isa},
        ); # $config_file
    } # foreach my $param ( @doom_params )
    return $command_line;
}

#############################################
# App::Mayhem::Utils->get_configfile_args() #
#############################################

=head2 get_configfile_args([@attributes])

Optional arugments:

=over

=item @attributes

A list of attributes to return to the caller.  If no attributes are passed in,
then will return all attributes.

Returns a scalar that contains all of the requested attributes in a
Windows-style INI configuration file.  If this method is passed a list of
attributes to return, returns only that list of attributes.  If an attribute
does not exist in this object, it's discarded, and an error message is logged.

=back

=cut

sub get_configfile_args {
    my $self = shift;
    my @requested_params = @_;
    my $log = Log::Log4perl->get_logger();
    $log->debug(LOGNAME . q(: get_configfile_args: entering method));

    # grab a copy of the metaobject for querying 'isa'
    my $meta = $self->meta();

    # grab a list of appropriate doom parameters (object attributes)
    my @doom_params = $self->get_attribute_list(@requested_params);

    my $config_file;
    if ( $self->can(q(config_block_header)) ) {
        $config_file .= $self->config_block_header() . qq(\n);
    } # if ( $doom->can(q(config_block_header)) )
    # we should either have a valid list of params (thanks to
    # _get_attribute_list above), or nothing, in which case this loop is
    # skipped
    foreach my $param ( sort(@doom_params) ) {
        # grab the meta-information for this attribute
        my $attr = $meta->get_attribute($param);
        # get the 'isa' that this attribute was defined with‥
        $log->debug(LOGNAME . qq(: checking parameter $param));
        $config_file .= $self->_parse_attribute(
            parse_type      => q(cfg_args),
            parameter       => $param,
            attribute_type  => $attr->{isa},
        ); # $config_file
    } # foreach my $param ( @doom_params )
    return $config_file;
}

############################################
# App::Mayhem::Utils->get_default_config() #
############################################

=head2 get_default_config()

Parse all of the object attributes and return a scalar that contains the
attributes as a list of options in a Windows-style INI configuration file,
along with the supporting documentation for those attributes.  If this method
is passed a list of attributes to return, returns only that list of
attributes.  If an attribute does not exist in this object, it's discarded,
and an error message is logged.

=cut

sub get_default_config {
    my $self = shift;
    my @requested_params = @_;
    my $log = Log::Log4perl->get_logger();
    $log->debug(LOGNAME . q(: get_default_config: entering method));

    # grab a copy of the metaobject for querying 'isa'
    my $meta = $self->meta();

    # grab a list of appropriate doom parameters (object attributes)
    my @doom_params = $self->get_attribute_list(@requested_params);

    my $config_file;
    # we should either have a valid list of params (thanks to
    # _get_attribute_list above), or nothing, in which case this loop is
    # skipped
    foreach my $param ( sort(@doom_params) ) {
        next if ( $param eq q(config_block_header) );
        $log->debug(LOGNAME . qq(: checking parameter $param));
        # grab the meta-information for this attribute
        my $attr = $meta->get_attribute($param);
        $config_file .= $attr->documentation();
        # get the 'isa' that this attribute was defined with
        $config_file .= $self->_parse_attribute(
            parse_type      => q(default_cfg),
            parameter       => $param,
            attribute_type  => $attr->{isa},
        ); # $config_file
    } # foreach my $param ( @doom_params )
    return $config_file;
}

##########################################
# App::Mayhem::Utils->_parse_attribute() #
##########################################

=head2 _parse_attribute()

Required arguments:

=over

=item parameter => $param

Parameter to parse and output.

=item attribute_type => $attribute

Attribute type of the above parameter; different attribute types need to be
written out in different ways (Strings are written differently than Booleans
for example).

=back

Parse the provided attribute, and return either the config file or command
line parameter to the caller.

=cut

sub _parse_attribute {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();
    $log->debug(q(_parse_attribute: entering method));

    $log->die(qq(_parse_attribute: missing 'attribute_type' argument))
        unless ( exists $args{attribute_type} );
    $log->die(qq(_parse_attribute: missing 'parameter' argument))
        unless ( exists $args{parameter} );
    $log->die(qq(_parse_attribute: missing 'parse_type' argument))
        unless ( exists $args{parse_type} );

    my $attr_type = $args{attribute_type};
    my $param = $args{parameter};
    my $parse_type = $args{parse_type};
    return q() if ( $param eq q(config_block_header) );
    $log->debug(qq(attribute_type is $attr_type));
    $log->debug(qq(parameter is $param));
    $log->debug(qq(parse_type is $parse_type));

    # config file options to be returned to the caller
    my $return_val = q();
    if ( $parse_type eq q(cmdline) ) {
        if ( $attr_type eq q(Str) || $attr_type eq q(Int) ) {
            # String parameters need both the key and value printed if the
            # attribute has a value, otherwise, don't print the parameter
            if ( defined $self->$param() ) {
                $return_val .= qq(-$param ) . $self->$param() . qq( );
            }
        } elsif ( $attr_type eq q(Bool) ) {
            # Booleans only need the parameter printed
            if ( $self->$param() == 1 ) {
                $return_val .= qq(-$param) . qq( );
            }
        } else {
            $log->warn(qq(_parse_attribute: Unhandled Moose attribute type: )
                . $attr_type);
        } # if ( $self->$param->isa() eq q(Str) )
    } elsif ( $parse_type eq q(default_cfg) || $parse_type eq q(cfg_args) ) {
        my $comment = q();
        my $eol = qq(\n);
        # add a comment character at the beginning of each attribute for the
        # default config file
        if ( $parse_type eq q(default_cfg) ) {
            $comment = q(#);
            $eol = qq(\n\n);
        } # if ( $parse_type eq q(default_cfg) )
        if ( $attr_type eq q(Str) || $attr_type eq q(Int) ) {
            if ( defined $self->$param() ) {
                # print a config parameter with it's value if defined
                $return_val .= $comment . qq($param = )
                    . $self->$param() . $eol;
            } else {
                # just print the parameter, don't try to print an undef value
                $return_val .= $comment . qq($param =$eol);
            } #  if ( defined $self->$param() )
        } elsif ( $attr_type eq q(Bool) ) {
            # if the boolean is not set, give it a 0 value
            if ( $self->$param() == 1 ) {
                $return_val .= $comment . qq($param = 1$eol);
            } else {
                $return_val .= $comment . qq($param = 0$eol);
            } # if ( $self->$param() == 1 )
        } else {
            $log->warn(qq(_parse_attribute: Unhandled Moose attribute type: )
                . $attr_type);
        } # if ( $self->$param->isa() eq q(Str) )
    } else {
        $log->die(qq(_parse_attribute: unknown parse type: $parse_type));
    } # if ( $parse_type = q(cmdline) )
    return $return_val;
}

=head1 OBJECT ATTRIBUTES

=head2 mayhem_base_dir

The base directory for all Mayhem module files.  Among other things, this
directory is needed in order for the L<lazy_use> method to be able to load new
modules.

=cut

has q(mayhem_base_dir)   => (
    is              => q(rw),
    isa             => q(Str),
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

1; # End of App::Mayhem::Utils
