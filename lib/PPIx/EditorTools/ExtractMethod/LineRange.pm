package PPIx::EditorTools::ExtractMethod::LineRange;
use Moose;
use Moose::Util::TypeConstraints;
use Params::Coerce;
has 'start'   => ( is => 'ro', isa => 'Int' );
has 'end'   => ( is => 'ro', isa => 'Int' );

coerce 'PPIx::EditorTools::ExtractMethod::LineRange'
      => from 'ArrayRef'
          => via { PPIx::EditorTools::ExtractMethod::LineRange->new( @{$_} ) };

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    return $class->$orig( 
        start => $_[0],
        end => $_[1]
    );
};

sub after_range {
    my ($self, $line_range) = @_;
    return __PACKAGE__->new( $line_range->end + 1, 99999999 );
}

sub all {
    my $class = shift ;
    return $class->new(0,99999999);
}

sub contains_line {
    my ($self, $line) = @_;
    return $self->start <= $line && $self->end >= $line;
}

sub is_before_line {
    my ($self, $line) = @_;
    return $self->end < $line;
}

sub cut_code {
    my ($self, $code) = @_;
    my @lines = split("\n", $code);
    return join "\n", @lines[($self->start-1)..($self->end-1)];
}

sub length {
    my $self = shift;
    return $self->end - $self->start + 1;
}
1;
