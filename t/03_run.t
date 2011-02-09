use strict;
use Test::More;

use App::puyopuyo;

{
    my $app = App::puyopuyo->new(
        width => 6,
        height => 13,
    );

    my $data =<<__LAYOUT__;
  GYRR
RYYGYG
GYGYRR
RYGYRG
YGYRYG
GYRYRG
YGYRYR
YGYRYR
YRRGRG
RYGYGG
GRYGYR
GRYGYR
GRYGYR
__LAYOUT__

    $app->load_puyo($data);
    my $stage = $app->run;

    my $answer = [];
    push @{$answer}, [] for (1..13);
    is_deeply($stage, $answer, "Zenkesi");
}

{

    my $app = App::puyopuyo->new(
        width => 6,
        height => 13,
    );

    my $data =<<__LAYOUT__;
 O
ORO
ORO
ORO
ORO
__LAYOUT__

    $app->load_puyo($data);
    my $stage = $app->run;

    my $answer = [];
    push @{$answer}, [] for (1..13);
    is_deeply($stage, $answer, "Ojama");

}

done_testing;
