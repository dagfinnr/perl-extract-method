package PPIx::EditorTools::ExtractMethod::VariableOccurrence;
use Moose;
has 'ppi_symbol'   => ( 
    is => 'ro', 
    isa => 'PPI::Token::Symbol',
    required => 1,
    handles => [ qw / content parent / ],
);

sub is_declaration {
    my $symb = $_[0]->ppi_symbol;
    return $symb->parent->child(0)->content eq 'my'
    && $symb->parent->child(2) == $symb;
}

sub variable_name {
    my $self = shift;
    return substr( $self->ppi_symbol->content, 1);
}
1;
