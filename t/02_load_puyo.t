use strict;
use Test::More;
use Test::Exception;

use App::puyopuyo;

{
    my $app = App::puyopuyo->new(width => 1, height => 1);
    can_ok($app, "load_puyo");

    my $data = "R\n";
    my $stage = $app->load_puyo($data);
    is_deeply($stage, [[ ord 'R']], "1x1 input Str");

    $stage = $app->load_puyo(\$data);
    is_deeply($stage, [[ ord 'R']], "1x1 input Str Ref");

    open my $fh, "<", \$data;
    $stage = $app->load_puyo($fh);
    is_deeply($stage, [[ ord 'R']], "1x1 input File Handle");
    close $fh;
}

{
    my $app = App::puyopuyo->new(width => 2, height => 2);

    my $data = "RR\nBB\n";
    my $stage = $app->load_puyo($data);
    is_deeply($stage, [[ ord 'B', ord 'R'], [ ord 'B', ord 'R' ]], "2x2");
}

{
    my $app = App::puyopuyo->new(width => 4, height => 3);

    my $data = "RRRR\nBBBB\nGGGG";
    my $stage = $app->load_puyo($data);
    is_deeply($stage, [
        [ ord 'G', ord 'B', ord 'R'],
        [ ord 'G', ord 'B', ord 'R'],
        [ ord 'G', ord 'B', ord 'R'],
        [ ord 'G', ord 'B', ord 'R'],
    ], "4x3");
}

{
    my $app = App::puyopuyo->new(width => 3, height => 3);

    my $data = "RRRR\nBBBB\nGGGG";
    dies_ok { $app->load_puyo($data) } "too long width";

    $data = "RRR\nBBB\nGGG\nYYY";
    dies_ok { $app->load_puyo($data) } "too long height";
}

done_testing;
