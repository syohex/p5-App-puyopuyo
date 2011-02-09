use strict;
use Test::More;

use App::puyopuyo;

{
    my $app = App::puyopuyo->new(width => 1, height => 1);
    can_ok($app, "load_puyo");

    my $data = "R\n";
    $app->load_puyo($data);
    is_deeply($app->stage, [[ ord 'R']], "1x1");
}

{
    my $app = App::puyopuyo->new(width => 2, height => 2);

    my $data = "RR\nBB\n";
    $app->load_puyo($data);
    is_deeply($app->stage, [[ ord 'B', ord 'R'], [ ord 'B', ord 'R' ]], "2x2");
}

{
    my $app = App::puyopuyo->new(width => 4, height => 3);

    my $data = "rrrr\nbbbb\ngggg";
    $app->load_puyo($data);
    is_deeply($app->stage, [
        [ ord 'G', ord 'B', ord 'R'],
        [ ord 'G', ord 'B', ord 'R'],
        [ ord 'G', ord 'B', ord 'R'],
        [ ord 'G', ord 'B', ord 'R'],
    ], "4x3");
}

done_testing;
