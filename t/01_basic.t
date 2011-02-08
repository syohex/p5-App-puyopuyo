use strict;
use Test::More;

use App::puyopuyo;

my $app = App::puyopuyo->new(width => 2, height => 2);
ok($app, "Constructer");
isa_ok($app, 'App::puyopuyo', "isa test");

is($app->width(), 2, "initialize width");
is($app->height(), 2, "initialize height");

done_testing;
