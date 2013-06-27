#!perl -T

use Test::More tests => 1;


BEGIN {
    use_ok( 'App::Mayhem' );
}

diag( qq(\nTesting App::Mayhem $App::Mayhem::VERSION,\nPerl $], $^X) );

# Mayhem inits Log::Log4perl, so we don't need our simple log4per initializer


# - Controller inits engines, one engine at a time
# - Engine checks for binaries, passes initialization status back to
# controller or to view (splashscreen)
# - Controller starts the main menu (sends a signal to the view object to
# bring up the main menu)
# - View object queries controller for a list of engine objects that can be
# played, each engine object will have a list of games that can be played
# - View sets up the GUI controls according to the users selections of game
# engine and game, i.e. if the user selects Hexen, then only the engines that
# support Hexen will be available
# - View updates the controller after the user makes a change, controller
# queries the view to get the current selections and applies them to the model
