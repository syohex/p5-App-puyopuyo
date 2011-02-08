use strict;
use Test::More;

use App::puyopuyo;

{
    my $app = App::puyopuyo->new(width => 1, height => 1);
    can_ok($app, "load_puyo");

    my $data = "r\n";
    $app->load_puyo($data);
    is_deeply($app->stage, [[ ord 'r']], "1x1");
}

{
    my $app = App::puyopuyo->new(width => 2, height => 2);

    my $data = "rr\nbb\n";
    $app->load_puyo($data);
    is_deeply($app->stage, [[ ord 'b', ord 'r'], [ ord 'b', ord 'r' ]], "2x2");
}

{
    my $app = App::puyopuyo->new(width => 4, height => 3);

    my $data = "rrrr\nbbbb\ngggg";
    $app->load_puyo($data);
    is_deeply($app->stage, [
        [ ord 'g', ord 'b', ord 'r'],
        [ ord 'g', ord 'b', ord 'r'],
        [ ord 'g', ord 'b', ord 'r'],
        [ ord 'g', ord 'b', ord 'r'],
    ], "4x3");
}

done_testing;
