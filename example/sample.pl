#!/usr/bin/perl
use strict;
use warnings;

use lib qw(../lib);
use Data::Section::Simple qw(get_data_section);

use utf8;
use App::puyopuyo;

binmode STDOUT, ":utf8";

my $app = App::puyopuyo->new(
    width => 6,
    height => 13,
    color => 1,
    puyo => '●',
    double_space => 1,
    animation => 1,
);

for my $section (1..5) {
    my $data = get_data_section("sample${section}");
    $app->load_puyo($data);
    $app->run;
}

__DATA__
@@ sample1
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

@@ sample2
  RRYB
  GGYG
  GGRR
 YYBGG
YGYRYG
RBBYBB
GYYRRB
GBGRYR
BRRBBY
YGRBYY
YGGRBR
GBBBRR

@@ sample3
 R
GRB BG
BBYYRY
BGGYGB
YGBYRY
YRRBBG
OYRBRG
GRYYRR
RYRBBG
RRGYYY
GGBRBB
BRRGGY
BBRGYY

@@ sample4
Y  YRR
Y BYGB
RGYGGY
BBYYRY
GBYGRB
GGRBBG
RYBYYG
RRYRRG
BYBBYY
YYGYBG
BRRGYB
BBGRRR
RRRGGB

@@ sample5
 O
ORO
ORO
ORO
ORO
