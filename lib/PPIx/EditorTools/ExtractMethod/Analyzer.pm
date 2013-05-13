package PPIx::EditorTools::ExtractMethod::Analyzer;
use PPI::Document;
use PPIx::EditorTools;
use PPIx::EditorTools::ExtractMethod::Variable;
use PPIx::EditorTools::ExtractMethod::VariableOccurrence;
use Set::Scalar;
use Moose;

has 'code'   => ( is => 'rw', isa => 'Str' );

has 'ppi'   => ( 
    is => 'rw', 
    isa => 'PPI::Document',
    lazy => 1,
    builder => '_build_ppi',
);


has 'start_selected'   => ( is => 'rw', isa => "Int" );
has 'end_selected'   => ( is => 'rw', isa => "Int" );

sub variables_in_selected {
    my $self = shift;
    my $symbols = $self->ppi->find(
        sub {
            $_[1]->isa('PPI::Token::Symbol')
            && $_[1]->location->[0] >= $self->start_selected
            && $_[1]->location->[0] <= $self->end_selected
        }
    );
    my %vars;
    foreach my $symbol ( @$symbols ) {
        my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
            ppi_symbol => $symbol
        );
        if (! defined $vars{$occurrence->variable_id} ) {
            $vars{$occurrence->variable_id} = PPIx::EditorTools::ExtractMethod::Variable->new(
                id => $occurrence->variable_id,
                name => $occurrence->variable_name,
                type => $occurrence->variable_type,
                declared_in_scope => 'before',
            );
        }
        if ($occurrence->is_declaration) {
            $vars{$occurrence->variable_id}->declared_in_scope('selected') ;
        }
    }
    return \%vars;
}

sub variables_after_selected {
    my $self = shift;
    my $inside_element =  PPIx::EditorTools::find_token_at_location(
        $self->ppi,
        [$self->start_selected, 1]);
    my $scope = $self->enclosing_scope($inside_element);
    my $symbols = $scope->find(
        sub {
            $_[1]->isa('PPI::Token::Symbol')
            && $_[1]->location->[0] > $self->end_selected
        }
    );
    my %vars;
    foreach my $symbol ( @$symbols ) {
        my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
            ppi_symbol => $symbol
        );
        if (! defined $vars{$occurrence->variable_id} ) {
            $vars{$occurrence->variable_id} = PPIx::EditorTools::ExtractMethod::Variable->new(
                id => $occurrence->variable_id,
                name => $occurrence->variable_name,
                type => $occurrence->variable_type,
                used_after => 1,
            );
        }
    }
    return \%vars;
}

sub output_variables {
    my $self = shift;
    my $inside_vars = $self->variables_in_selected;
    my $after_vars = $self->variables_after_selected;
    foreach my $id ( keys %$inside_vars ) {
        if (defined $after_vars->{$id}) {
            $inside_vars->{$id}->used_after(1);
        }
    }
    return $inside_vars;
}

sub enclosing_scope {
    my ($self, $element) = @_;
    $element = $element->parent;
    while (!$element->scope) {
        $element = $element->parent;
    }
    return $element;
}

sub _build_ppi {
    my $self = shift;
    my $code = $self->code;
    return PPI::Document->new(\$code);
}

1;
