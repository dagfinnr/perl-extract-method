package PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion;
use Moose;
use PPI::Document;
use PPIx::EditorTools::ExtractMethod::LineRange;

has 'ppi'   => ( is => 'ro', isa => 'Object' );

has 'selected_range' => (
    is => 'rw',
    isa => 'PPIx::EditorTools::ExtractMethod::LineRange',
    coerce => 1,
);

has 'scope'   => ( is => 'ro', isa => 'PPI::Element' );


sub find_symbols {
    my $self = shift ;
    my $finder = sub {
        $_[1]->isa('PPI::Token::Symbol')
        && $self->selected_range->contains_line($_[1]->location->[0]);
    };
    if ($self->selected_range && !$self->scope) {
        return $self->ppi->find($finder) || [];
    }
    if ($self->selected_range && $self->scope) {
        return $self->scope->find($finder) || [];
    }
    return $self->ppi->find('PPI::Token::Symbol') || [];
}

1;

