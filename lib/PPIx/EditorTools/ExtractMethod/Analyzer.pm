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

sub found_variables {
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

sub relevant_variables {
    my $self = shift;
    my $inside_vars = $self->found_variables;
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
__END__
sub _build_code_with_sub {
    my $self = shift;
    my @lines = split("\n", $self->code);
    splice @lines, $self->end_selected, 0, '}';
    splice @lines, $self->start_selected - 1, 0, '   sub ppi_temp {';
    return join "\n", @lines;
}

sub _build_ppi {
    my $self = shift;
    my $code = $self->code_with_sub;
    return PPI::Document->new(\$code);
}

sub used_variables {
    my $self = shift;
    my $vars = {};
    foreach my $occurrence ($self->symbols) {
        my $var = $occurrence->content;
        my $name = substr( $var, 1 );
        if (! defined $vars->{ $name } ) {
            $vars->{ $name } = PPIx::EditorTools::ExtractMethod::Variable->new(
                name => $name
            );
        }
        if ($occurrence->is_declaration) {
            $vars->{ $name }->declared_in_scope($self->scope_category($occurrence));
        }
        else {
            $vars->{ $name }->used_in_scope($self->scope_category($occurrence));
        }
    }
    return $vars;
}

sub symbols {
    my $self = shift;
    my $symbols = $self->ppi->find( 
        sub { $_[1]->isa('PPI::Token::Symbol') and $_[1]->content }
    );
    $symbols ||= [];
    return map { PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(ppi_symbol => $_) } @$symbols;
}

sub variable_declarations {
    my $self = shift;
    my $symbols = $self->ppi->find( 
        sub { $_[1]->isa('PPI::Statement::Variable') }
    );
    $symbols ||= [];
    return @$symbols;
}


1;
