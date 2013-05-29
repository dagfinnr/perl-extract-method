package PPIx::EditorTools::ExtractMethod::VariableOccurrence;
use Moose;
has 'ppi_symbol'   => ( 
    is => 'ro', 
    isa => 'PPI::Token::Symbol',
    required => 1,
    handles => [ qw / content parent / ],
);

has 'is_single_declaration'   => ( is => 'ro', isa => 'Bool' );
has 'is_list_declaration'   => ( is => 'ro', isa => 'Bool' );
has 'is_loop_variable_declaration'   => ( is => 'ro', isa => 'Bool' );
has 'variable_type'   => ( is => 'ro', isa => 'Str' );
has 'variable_name'   => ( is => 'ro', isa => 'Str' );


sub is_declaration {
    return $_[0]->is_single_declaration() ||
    $_[0]->is_loop_variable_declaration ||
    $_[0]->is_list_declaration();
}

sub variable_id {
    my $self = shift;
    return $self->variable_type . $self->variable_name;
}

1;
