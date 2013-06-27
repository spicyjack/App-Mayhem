#!perl -T

use Test::More tests => 1;
use Log::Log4perl qw(:easy);
use Glib;

BEGIN {
    use_ok( 'App::Mayhem::View::MainMenu' );
}

Log::Log4perl->easy_init($WARN);
#Log::Log4perl->easy_init($DEBUG);

Glib::Timeout->add(5000, sub { exit 0; } );
my $mainmenu = App::Mayhem::View::MainMenu->new(compact => 1);

diag( qq(\nTesting App::Mayhem $App::Mayhem::View::MainMenu::VERSION,\n)
 . qq(Perl $], $^X) );
