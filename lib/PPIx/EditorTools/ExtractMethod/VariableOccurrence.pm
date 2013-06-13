package PPIx::EditorTools::ExtractMethod::VariableOccurrence;
use Moose;
has 'ppi_symbol'   => ( 
    is => 'ro', 
    isa => 'PPI::Token::Symbol',
    required => 1,
    handles => [ qw / content parent / ],
);

has 'is_single_declaration'   => ( is => 'ro', isa => 'Bool', default => 0 );
has 'is_multi_declaration'   => ( is => 'ro', isa => 'Bool', default => 0 );
has 'is_loop_variable_declaration'   => ( is => 'ro', isa => 'Bool', default => 0 );
has 'variable_type'   => ( is => 'ro', isa => 'Str' );
has 'variable_name'   => ( is => 'ro', isa => 'Str' );
has 'is_changed'   => ( is => 'ro', isa => 'Bool', default => 0 );
has 'is_incremented'   => ( is => 'ro', isa => 'Bool', default => 0 );
has 'is_decremented'   => ( is => 'ro', isa => 'Bool', default => 0 );
has 'is_in_assignment'   => ( is => 'ro', isa => 'Bool', default => 0 );
has 'location'   => ( is => 'ro', isa => 'Maybe[ArrayRef]', default => sub{ [ 1, 1, 1, 1 ] } );

sub is_declaration {
    return $_[0]->is_single_declaration() ||
    $_[0]->is_loop_variable_declaration ||
    $_[0]->is_multi_declaration();
}

sub variable_id {
    my $self = shift;
    return $self->variable_type . $self->variable_name;
}

1;
