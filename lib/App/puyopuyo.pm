package App::puyopuyo;
use strict;
use warnings;
use 5.008_001;

use Class::Accessor::Lite (
    rw  => [ qw(stage width height color puyo animation) ],
);

use Term::ANSIColor ();
use List::MoreUtils qw(none);

our $VERSION = '0.01';

# constant values
my $SPACE  = ord ' ';
my $ERASED = -1;

my ($ROW_MAX, $COLUMN_MAX);

sub new {
    my ($class, %args) = @_;

    my $width  = delete $args{width};
    my $height = delete $args{height};
    my $color  = delete $args{color} || 0;
    my $puyo   = delete $args{puyo};
    my $animation = delete $args{animation} || 0;

    unless ($width && $height) {
        Carp::croak("Error: please specify 'width' and 'height'\n");
    }

    my $self = bless {}, $class;

    $self->width($width);
    $self->height($height);
    $self->color($color);
    $self->puyo($puyo);
    $self->animation($animation);

    $ROW_MAX    = $height - 1;
    $COLUMN_MAX = $width - 1;

    return $self;
}

sub load_puyo {
    my ($self, $data) = @_;

    my $input_data;
    if (ref $data ne '') {
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

        unshift @rows, [ map { ord $_; } @puyos];
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
            push @cols, defined $puyo ? $puyo : $SPACE;
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
            push @row_puyos, defined $puyo ? $puyo : $SPACE;
        }
        push @rows, [ @row_puyos ];
    }

    return [ @rows ];
}

sub run {
    my $self = shift;
    my $stage = $self->stage;

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

        if ($self->animation) {
            $self->print_stage();
            sleep 1;
        }
    }

    $self->_coloumns_to_rows($self->stage);
}

sub _move_puyo {
    my $self = shift;
    my $col_max = $self->width - 1;

    for my $col (@{$self->stage}) {
        my @puyos = grep { $_ >= 1 } @{$col};
        my $length = length @puyos;
        push @puyos, $SPACE for ($length..$col_max);
        $col = \@puyos;
    }
}

sub _erase_puyo {
    my ($self, $neighbors) = @_;

    for my $neighbor (@{$neighbors}) {
        my ($x, $y) = @{$neighbor}[0,1];
        $self->stage->[$x]->[$y] = $ERASED;
    }
}

sub _search_same_puyo {
    my ($stage, $color, $col, $row, $neighbors) = @_;
    my $puyo = $stage->[$col]->[$row];

    return unless defined $puyo;
    return if $puyo == $SPACE || $puyo == $ERASED;
    return if $color != $puyo;

    push @{$neighbors}, [$col, $row];

    for my $c ($col-1, $col+1) {
        next unless $c >= 0 && $c <= $COLUMN_MAX;
        if (is_already_checked($c, $row, $neighbors)
                && defined $stage->[$c]->[$row] && $color == $stage->[$c]->[$row]) {
            _search_same_puyo($stage, $color, $c, $row, $neighbors);
        }
    }

    return unless $row+1 >= 0 && $row <= $ROW_MAX;
    if (is_already_checked($col, $row+1, $neighbors)
            && defined $stage->[$col]->[$row+1] && $color == $stage->[$col]->[$row+1]) {
        _search_same_puyo($stage, $color, $col, $row+1, $neighbors);
    }
}

sub print_stage {
    my $self = shift;

    for (my $row = $ROW_MAX; $row >= 0; $row--) {
        for (my $col = 0; $col <= $COLUMN_MAX; $col++) {
            my $puyo = $self->stage->[$col]->[$row];
            next unless defined $puyo;

            $self->_print_puyo($puyo);
        }
        print "\n";
    }
    print "\n"
}

my %COLORS = (
    R => 'red', B => 'blue', G => 'green', Y => 'yellow',
);

sub _print_puyo {
    my ($self, $puyo_ord) = @_;

    my $chr = chr $puyo_ord;
    if ($self->color) {
        if (exists $COLORS{$chr}) {
            print Term::ANSIColor::color $COLORS{$chr};
            print defined $self->puyo ? $self->puyo : $chr;
            print Term::ANSIColor::color 'reset';
        } else {
            print $chr;
        }
    } else {
        print $chr;
    }
}

sub is_already_checked {
    my ($col, $row, $neighbors) = @_;
    return none { $_->[0] == $col && $_->[1] == $row} @{$neighbors};
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
