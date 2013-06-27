#!perl -T

package MayhemTest;

use strict;
use warnings;
use Time::HiRes qw(usleep);

# a set of functions used in testing Mayhem modules

sub new {
    my $class = shift;
    # bless us an object of this class and return it to the caller
    my $self = bless ({}, $class);
    return $self;
}

# write to the socket, add the network line endings to keep things happy
sub write_socket {
    my $self = shift;
    my %args = @_;

    die qq(Missing socket argument to write_socket method!)
        unless(exists $args{socket});
    die qq(Missing message argument to write_socket method!)
        unless(exists $args{message});

    my $socket = $args{socket};
    my $message = $args{message};
    my $sleep_time = $args{sleep};
    if ( ! defined $sleep_time ) { $sleep_time = 0;}
    #usleep(1000);
    print $socket qq($message\015\012);
    sleep $sleep_time;
}

# read from the socket, strip line endings
sub read_socket {
    my $self = shift;
    my $socket = shift;

    my $message = <$socket>;
    $message =~ s/\015\012$//;
    return $message;
}

1;
# vim: filetype=perl shiftwidth=4 tabstop=4:
# конец!
