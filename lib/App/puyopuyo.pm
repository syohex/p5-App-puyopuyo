package App::puyopuyo;
use strict;
use warnings;
use 5.008_001;

use Class::Accessor::Lite (
    rw  => [ qw(stage width height color puyo space animation) ],
);

use Term::ANSIColor ();

our $VERSION = '0.01';

# constant values
my $ERASED = -1;
my $OJAMA  = ord 'O';

# color palette
my %COLORS = (
    R => 'red', B => 'blue', G => 'green',
    Y => 'yellow', C => 'cyan', M => 'magenta',
    O => 'white', # 'O' means Ojama puyo.
);

my ($ROW_MAX, $COLUMN_MAX);

sub new {
    my ($class, %args) = @_;

    my $width  = delete $args{width};
    my $height = delete $args{height};
    my $color  = delete $args{color} || 0;
    my $puyo   = delete $args{puyo};
    my $double_space  = delete $args{double_space} || undef;
    my $animation = delete $args{animation} || 0;

    unless ($width && $height) {
        Carp::croak("Error: please specify 'width' and 'height'\n");
    }

    my $self = bless {}, $class;

    $self->width($width);
    $self->height($height);
    $self->color($color);
    $self->puyo($puyo);
    $self->space( defined $double_space ? '  ' : ' ');
    $self->animation($animation);

    $ROW_MAX    = $height - 1;
    $COLUMN_MAX = $width - 1;

    return $self;
}

sub load_puyo {
    my ($self, $data) = @_;

    my $input_data;
    if (ref $data) {
        if (ref $data eq 'GLOB' || ref $data eq 'SCALAR') {
            $input_data = $data;
        } else {
            Carp::croak("Error: invalid data type. "
                            . "It should be string or string ref or FILE handle\n");
        }
    } else {
        $input_data = \$data;
    }

    open my $fh, "<", $input_data or Carp::croak("Can't read input data\n");
    my @puyo_lines = <$fh>;
    close $fh;

    @puyo_lines = grep { !m{^\s*$} } @puyo_lines;

    if (length @puyo_lines > $self->height) {
        Carp::croak("Input puyo is too long height\n");
    }

    my @rows;
    for my $puyo_line (@puyo_lines) {
        chomp $puyo_line;
        my @puyos = split //, $puyo_line;

        if (length @puyos > $self->width) {
            Carp::croak("Input puyo is too long width\n");
        }

        unshift @rows, [ map { ord (uc $_); } @puyos];
    }

    my $stage = $self->_rows_to_columns( \@rows );
    $self->stage( $stage );
}

sub _rows_to_columns {
    my ($self, $rows_ref) = @_;

    my @columns;
    for my $col (0..$COLUMN_MAX) {
        my @cols;
        for my $row (0..$ROW_MAX) {
            my $puyo = $rows_ref->[$row]->[$col];
            push @cols, $puyo;
        }
        push @columns, [ @cols ];
    }

    return [ @columns ];
}

sub _coloumns_to_rows {
    my ($self, $columns_ref) = @_;

    my @rows;
    for my $j (0..$ROW_MAX) {
        my @row_puyos;
        for my $i (0..$COLUMN_MAX) {
            my $puyo = $columns_ref->[$i]->[$j];
            push @row_puyos, $puyo;
        }
        push @rows, [ @row_puyos ];
    }

    return [ @rows ];
}

sub run {
    my $self = shift;
    my $stage = $self->stage;

    $self->_animate if $self->animation;

    my ($erase_num, $rensa) = (0, 0);
    while (1) {
        $erase_num = 0;
        for my $col (0..$COLUMN_MAX) {
            for my $row (0..$ROW_MAX) {
                my $neighbors = [];
                my $puyo = $stage->[$col]->[$row];

                _search_same_puyo($stage, $puyo, $col, $row, $neighbors);

                if (scalar @{$neighbors} >= 4) {
                    $self->_erase_puyo($neighbors);
                    $erase_num++;
                }
            }
        }

        last if $erase_num == 0;

        $self->_move_puyo();
        $self->_animate(++$rensa) if $self->animation;
    }

    $self->_coloumns_to_rows($self->stage);
}

sub _animate {
    my ($self, $rensa) = @_;

    _clear_terminal();
    $self->print_stage();
    printf "%d combo\n", $rensa if defined $rensa;
    sleep 1;
}

sub _move_puyo {
    my $self = shift;
    my $col_max = $self->width - 1;

    for my $col (@{$self->stage}) {
        my @puyos = grep { $_ >= 1 } @{$col};
        my $length = length @puyos;
        $col = \@puyos;
    }
}

sub _erase_puyo {
    my ($self, $neighbors) = @_;
    my $stage = $self->stage;

    for my $neighbor (@{$neighbors}) {
        my ($x, $y) = @{$neighbor}[0,1];
        $stage->[$x]->[$y] = $ERASED;

        for my $row ($y-1, $y+1) {
            next unless $row >= 0 && $row <= $ROW_MAX;
            next unless defined $stage->[$x]->[$row];
            next unless $stage->[$x]->[$row] == $OJAMA;
            $stage->[$x]->[$row] = $ERASED;
        }

        for my $col ($x-1, $x+1) {
            next unless $col >= 0 && $col <= $COLUMN_MAX;
            next unless defined $self->stage->[$col]->[$y];
            next unless $stage->[$col]->[$y] == $OJAMA;
            $stage->[$col]->[$y] = $ERASED;
        }
    }
}

sub _search_same_puyo {
    my ($stage, $color, $col, $row, $neighbors) = @_;
    my $puyo = $stage->[$col]->[$row];

    return if !defined $puyo || $puyo == $ERASED || $puyo == $OJAMA;
    return if $color != $puyo;

    push @{$neighbors}, [$col, $row];

    for my $c ($col-1, $col+1) {
        next unless $c >= 0 && $c <= $COLUMN_MAX;
        next if is_already_checked($c, $row, $neighbors);
        next unless defined $stage->[$c]->[$row];
        if ($color == $stage->[$c]->[$row]) {
            _search_same_puyo($stage, $color, $c, $row, $neighbors);
        }
    }

    for my $r ($row-1, $row+1) {
        next unless $r >= 0 && $r <= $ROW_MAX;
        next if is_already_checked($col, $r, $neighbors);
        next unless defined $stage->[$col]->[$r];
        if ($color == $stage->[$col]->[$r]) {
            _search_same_puyo($stage, $color, $col, $r, $neighbors);
        }
    }
}

sub print_stage {
    my $self = shift;

    for (my $row = $ROW_MAX; $row >= 0; $row--) {
        for (my $col = 0; $col <= $COLUMN_MAX; $col++) {
            my $puyo = defined $self->stage->[$col]->[$row]
                ? $self->stage->[$col]->[$row] : ord ' ';

            $self->_print_puyo($puyo);
        }
        print "\n";
    }
    print "\n"
}

sub _print_puyo {
    my ($self, $puyo) = @_;

    my $chr = chr $puyo;
    if ($chr eq ' ') {
            print $self->space;
    } else {
        if ($self->color) {
            print Term::ANSIColor::color $COLORS{$chr};
            print defined $self->puyo ? $self->puyo : $chr;
            print Term::ANSIColor::color 'reset';
        } else {
            print $chr;
        }
    }
}

sub _any(&@) {
    my $cb = shift;

    for my $element (@_) {
        local $_ = $element;
        return 1 if $cb->($element);
    }
    return 0;
}

sub is_already_checked {
    my ($col, $row, $neighbors) = @_;
    return _any { $_->[0] == $col && $_->[1] == $row } @{$neighbors};
}

sub _clear_terminal {
    my $clear_cmd = $^O eq 'MSWin32' ? 'cls' : 'clear';
    system $clear_cmd;
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

App::puyopuyo - PuyoPuyo resolver

=head1 SYNOPSIS

  use App::puyopuyo;

  my $app = App::puyopuyo->new(width => 6, height => 13, animation => 1);
  $app->load_puyo("rrgg\nggrr\nyybb\n");

=head1 DESCRIPTION

App::puyopuyo is

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2011- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
