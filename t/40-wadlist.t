#!perl -T

use Test::More tests => 1;

# FIXME use the file extension '*.wli' for wad lists; stands for WadLIst

BEGIN {
    use_ok( 'App::Mayhem' );
}

diag( qq(\nTesting App::Mayhem $App::Mayhem::VERSION,\nPerl $], $^X) );

my $doom1_wad_wadlist = <<EOD1;
[WADList]
E1M1 =
E1M2 =
EOD1

my $doom2_wad_wadlist = <<EOD2;
[WADList]
MAP01 =
MAP02 =
EOD2

my $sample_wadlist = q();

TODO: {
    local $TODO = qq(Doom WAD wadlist parser not written yet);

    is($doom1_wad_wadlist, $sample_wadlist, q(Doom I WAD wadlist matches));
    is($doom2_wad_wadlist, $sample_wadlist, q(Doom II WAD wadlist matches));
} # TODO:

